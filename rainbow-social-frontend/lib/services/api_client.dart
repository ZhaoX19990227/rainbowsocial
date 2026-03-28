import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class MultipartUploadFile {
  const MultipartUploadFile({
    required this.field,
    required this.filename,
    required this.bytes,
  });

  final String field;
  final String filename;
  final Uint8List bytes;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _send(
      () => http.get(uri, headers: _headers(token)),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(
      () => http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    String? token,
    required List<MultipartUploadFile> files,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.headers.addAll(_headers(token, includeContentType: false));
    if (fields != null) {
      request.fields.addAll(fields);
    }
    for (final entry in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          entry.field,
          entry.bytes,
          filename: entry.filename,
        ),
      );
    }

    final streamed = await _send(request.send);
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('连接超时，请检查当前后端地址或网络状态', statusCode: 0);
    } on SocketException {
      throw const ApiException('无法连接服务器，请检查当前后端地址或网络状态', statusCode: 0);
    } on http.ClientException {
      throw const ApiException('请求发送失败，请稍后重试', statusCode: 0);
    }
  }

  Map<String, String> _headers(
    String? token, {
    bool includeContentType = true,
  }) {
    return {
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final payload = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        '${payload['error'] ?? 'Request failed'}',
        statusCode: response.statusCode,
      );
    }
    return payload;
  }
}

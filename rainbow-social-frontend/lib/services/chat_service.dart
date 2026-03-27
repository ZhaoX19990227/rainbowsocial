import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';
import 'api_client.dart';

class ChatService {
  ChatService(this._client);

  final ApiClient _client;

  WebSocketChannel connect({
    required String wsBaseUrl,
    required int userId,
    required String token,
  }) {
    final uri = Uri.parse(wsBaseUrl).replace(queryParameters: {
      'user_id': '$userId',
      'token': token,
    });
    return WebSocketChannel.connect(uri);
  }

  Future<List<ChatThread>> fetchThreads(String token) async {
    final response = await _client.get('/conversations', token: token);
    final items = response['data'] as List<dynamic>;
    return items
        .map((item) => ChatThread.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageModel>> fetchMessages({
    required String token,
    required int peerId,
    int limit = 30,
    int? beforeId,
  }) async {
    final response = await _client.get(
      '/conversations/$peerId/messages',
      token: token,
      query: {
        'limit': '$limit',
        if (beforeId != null && beforeId > 0) 'before_id': '$beforeId',
      },
    );
    final items = response['data'] as List<dynamic>;
    return items
        .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markConversationRead({
    required String token,
    required int peerId,
  }) async {
    await _client.post('/conversations/$peerId/read', token: token);
  }

  Future<void> setConversationPinned({
    required String token,
    required int peerId,
    required bool isPinned,
  }) async {
    await _client.put(
      '/conversations/$peerId/pin',
      token: token,
      body: {'is_pinned': isPinned},
    );
  }

  String encodeOutbound({
    required String clientMessageId,
    required int toUser,
    required String content,
    String type = 'text',
    String mediaUrl = '',
    int durationSeconds = 0,
  }) {
    return jsonEncode({
      'client_message_id': clientMessageId,
      'to_user': toUser,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'duration_seconds': durationSeconds,
    });
  }
}

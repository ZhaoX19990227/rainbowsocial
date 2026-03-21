import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';
import 'api_client.dart';
import 'app_flags.dart';
import 'mock_social_data.dart';

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
    try {
      final response = await _client.get('/conversations', token: token);
      final items = response['data'] as List<dynamic>;
      return items
          .map((item) => ChatThread.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      return MockSocialData.threads;
    }
  }

  Future<List<ChatMessageModel>> fetchMessages({
    required String token,
    required int peerId,
    int limit = 30,
    int? beforeId,
  }) async {
    try {
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
          .map(
              (item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      final items = MockSocialData.initialMessages(99, peerId);
      if (beforeId != null && beforeId > 0) {
        return const [];
      }
      return items.take(limit).toList();
    }
  }

  Future<void> markConversationRead({
    required String token,
    required int peerId,
  }) async {
    try {
      await _client.post('/conversations/$peerId/read', token: token);
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
    }
  }

  Future<void> setConversationPinned({
    required String token,
    required int peerId,
    required bool isPinned,
  }) async {
    try {
      await _client.put(
        '/conversations/$peerId/pin',
        token: token,
        body: {'is_pinned': isPinned},
      );
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
    }
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

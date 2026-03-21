import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';
import '../services/chat_service.dart';

class ChatRepository {
  const ChatRepository(this._service);

  final ChatService _service;

  Future<List<ChatThread>> fetchThreads(String token) =>
      _service.fetchThreads(token);

  Future<List<ChatMessageModel>> fetchMessages({
    required String token,
    required int peerId,
    int limit = 30,
    int? beforeId,
  }) =>
      _service.fetchMessages(
        token: token,
        peerId: peerId,
        limit: limit,
        beforeId: beforeId,
      );

  Future<void> markConversationRead({
    required String token,
    required int peerId,
  }) =>
      _service.markConversationRead(token: token, peerId: peerId);

  Future<void> setConversationPinned({
    required String token,
    required int peerId,
    required bool isPinned,
  }) =>
      _service.setConversationPinned(
        token: token,
        peerId: peerId,
        isPinned: isPinned,
      );

  String encodeOutbound({
    required String clientMessageId,
    required int toUser,
    required String content,
    String type = 'text',
    String mediaUrl = '',
    int durationSeconds = 0,
  }) =>
      _service.encodeOutbound(
        clientMessageId: clientMessageId,
        toUser: toUser,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        durationSeconds: durationSeconds,
      );
}

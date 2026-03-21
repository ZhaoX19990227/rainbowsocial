import 'app_user.dart';
import 'chat_message_model.dart';

class ChatThread {
  const ChatThread({
    required this.peer,
    required this.lastMessage,
    required this.unreadCount,
    required this.isPinned,
  });

  final AppUser peer;
  final ChatMessageModel lastMessage;
  final int unreadCount;
  final bool isPinned;

  ChatThread copyWith({
    AppUser? peer,
    ChatMessageModel? lastMessage,
    int? unreadCount,
    bool? isPinned,
  }) {
    return ChatThread(
      peer: peer ?? this.peer,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      peer: AppUser.fromJson(json['peer_user'] as Map<String, dynamic>),
      lastMessage: ChatMessageModel(
        id: 0,
        clientMessageId: '${json['client_message_id'] ?? ''}',
        fromUser: ((json['peer_user'] as Map<String, dynamic>)['id'] as num?)
                ?.toInt() ??
            0,
        toUser: 0,
        content: '${json['last_message'] ?? ''}'.isEmpty
            ? '已匹配，打个招呼吧'
            : ('${json['last_type'] ?? 'text'}' == 'audio'
                ? '语音消息'
                : '${json['last_message'] ?? ''}'),
        type: '${json['last_type'] ?? 'text'}',
        timestamp: DateTime.tryParse('${json['last_message_at'] ?? ''}') ??
            DateTime.now(),
      ),
      unreadCount: ((json['unread_count'] ?? 0) as num).toInt(),
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
    );
  }
}

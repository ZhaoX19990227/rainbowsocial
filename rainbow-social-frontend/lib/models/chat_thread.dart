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
        fromUser: ((json['last_from_user'] ?? 0) as num).toInt(),
        toUser: ((json['last_to_user'] ?? 0) as num).toInt(),
        content: '${json['last_message'] ?? ''}'.isEmpty
            ? '已匹配，打个招呼吧'
            : ('${json['last_type'] ?? 'text'}' == 'audio'
                ? '语音消息'
                : '${json['last_message'] ?? ''}'),
        type: '${json['last_type'] ?? 'text'}',
        deliveryStatus: _deliveryStatusFromJson('${json['delivery_status'] ?? ''}'),
        timestamp: DateTime.tryParse('${json['last_message_at'] ?? ''}') ??
            DateTime.now(),
      ),
      unreadCount: ((json['unread_count'] ?? 0) as num).toInt(),
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
    );
  }

  static ChatDeliveryStatus _deliveryStatusFromJson(String value) {
    switch (value) {
      case 'read':
        return ChatDeliveryStatus.read;
      case 'delivered':
        return ChatDeliveryStatus.delivered;
      default:
        return ChatDeliveryStatus.none;
    }
  }
}

enum ChatMessageStatus {
  sending,
  sent,
  failed,
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.clientMessageId,
    required this.fromUser,
    required this.toUser,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
    this.errorMessage,
  });

  final int id;
  final String clientMessageId;
  final int fromUser;
  final int toUser;
  final String content;
  final String type;
  final DateTime timestamp;
  final ChatMessageStatus status;
  final String? errorMessage;

  bool isMine(int currentUserId) => fromUser == currentUserId;
  bool get isPending => status == ChatMessageStatus.sending;
  bool get isFailed => status == ChatMessageStatus.failed;

  ChatMessageModel copyWith({
    int? id,
    String? clientMessageId,
    int? fromUser,
    int? toUser,
    String? content,
    String? type,
    DateTime? timestamp,
    ChatMessageStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      fromUser: fromUser ?? this.fromUser,
      toUser: toUser ?? this.toUser,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: ((json['id'] ?? 0) as num).toInt(),
      clientMessageId: '${json['client_message_id'] ?? ''}',
      fromUser: ((json['from_user'] ?? 0) as num).toInt(),
      toUser: ((json['to_user'] ?? 0) as num).toInt(),
      content: '${json['content'] ?? ''}',
      type: '${json['type'] ?? 'text'}',
      timestamp:
          DateTime.tryParse('${json['timestamp'] ?? ''}') ?? DateTime.now(),
      status: ChatMessageStatus.sent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_message_id': clientMessageId,
      'from_user': fromUser,
      'to_user': toUser,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum ChatMessageStatus {
  sending,
  sent,
  failed,
}

enum ChatDeliveryStatus {
  none,
  delivered,
  read,
}

class ChatReplyPreview {
  const ChatReplyPreview({
    required this.messageId,
    this.clientMessageId = '',
    required this.fromUser,
    required this.type,
    required this.content,
    this.mediaUrl = '',
  });

  final int messageId;
  final String clientMessageId;
  final int fromUser;
  final String type;
  final String content;
  final String mediaUrl;

  bool get isImage => type == 'image';
  bool get isFlashImage => type == 'flash_image';
  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';

  factory ChatReplyPreview.fromJson(Map<String, dynamic> json) {
    return ChatReplyPreview(
      messageId: ((json['message_id'] ?? json['id'] ?? 0) as num).toInt(),
      clientMessageId: '${json['client_message_id'] ?? ''}',
      fromUser: ((json['from_user'] ?? 0) as num).toInt(),
      type: '${json['type'] ?? 'text'}',
      content: '${json['content'] ?? ''}',
      mediaUrl: '${json['media_url'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'client_message_id': clientMessageId,
      'from_user': fromUser,
      'type': type,
      'content': content,
      'media_url': mediaUrl,
    };
  }
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
    this.mediaUrl = '',
    this.durationSeconds = 0,
    this.replyToMessageId = 0,
    this.replyPreview,
    this.localFilePath,
    this.status = ChatMessageStatus.sent,
    this.deliveryStatus = ChatDeliveryStatus.none,
    this.errorMessage,
  });

  final int id;
  final String clientMessageId;
  final int fromUser;
  final int toUser;
  final String content;
  final String type;
  final DateTime timestamp;
  final String mediaUrl;
  final int durationSeconds;
  final int replyToMessageId;
  final ChatReplyPreview? replyPreview;
  final String? localFilePath;
  final ChatMessageStatus status;
  final ChatDeliveryStatus deliveryStatus;
  final String? errorMessage;

  bool isMine(int currentUserId) => fromUser == currentUserId;
  bool get isPending => status == ChatMessageStatus.sending;
  bool get isFailed => status == ChatMessageStatus.failed;
  bool get isAudio => type == 'audio';
  bool get isImage => type == 'image';
  bool get isFlashImage => type == 'flash_image';
  bool get isFlirty => type == 'flirt';
  String get audioSource =>
      mediaUrl.isNotEmpty ? mediaUrl : (localFilePath ?? '');
  String get imageSource =>
      mediaUrl.isNotEmpty ? mediaUrl : (localFilePath ?? '');
  String get flirtyActionId => mediaUrl;

  ChatMessageModel copyWith({
    int? id,
    String? clientMessageId,
    int? fromUser,
    int? toUser,
    String? content,
    String? type,
    DateTime? timestamp,
    String? mediaUrl,
    int? durationSeconds,
    int? replyToMessageId,
    ChatReplyPreview? replyPreview,
    String? localFilePath,
    ChatMessageStatus? status,
    ChatDeliveryStatus? deliveryStatus,
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
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyPreview: replyPreview ?? this.replyPreview,
      localFilePath: localFilePath ?? this.localFilePath,
      status: status ?? this.status,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
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
      mediaUrl: '${json['media_url'] ?? ''}',
      durationSeconds: ((json['duration_seconds'] ?? 0) as num).toInt(),
      replyToMessageId: ((json['reply_to_message_id'] ?? 0) as num).toInt(),
      replyPreview: json['reply_preview'] is Map
          ? ChatReplyPreview.fromJson(
              Map<String, dynamic>.from(json['reply_preview'] as Map),
            )
          : null,
      status: ChatMessageStatus.sent,
      deliveryStatus:
          _deliveryStatusFromJson('${json['delivery_status'] ?? ''}'),
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
      'media_url': mediaUrl,
      'duration_seconds': durationSeconds,
      'reply_to_message_id': replyToMessageId,
      'reply_preview': replyPreview?.toJson(),
      'delivery_status': switch (deliveryStatus) {
        ChatDeliveryStatus.read => 'read',
        ChatDeliveryStatus.delivered => 'delivered',
        ChatDeliveryStatus.none => '',
      },
      'timestamp': timestamp.toIso8601String(),
    };
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

import '../models/chat_message_model.dart';

class ChatRoomState {
  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.sendingCount = 0,
    this.errorMessage,
  });

  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int sendingCount;
  final String? errorMessage;

  bool get isSending => sendingCount > 0;

  ChatRoomState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? sendingCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      sendingCount: sendingCount ?? this.sendingCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

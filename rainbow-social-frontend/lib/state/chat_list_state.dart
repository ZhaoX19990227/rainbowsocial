import '../models/chat_thread.dart';

class ChatListState {
  const ChatListState({
    this.threads = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ChatThread> threads;
  final bool isLoading;
  final String? errorMessage;

  ChatListState copyWith({
    List<ChatThread>? threads,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatListState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

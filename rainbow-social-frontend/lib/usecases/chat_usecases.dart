import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';
import '../providers/app_providers.dart';
import '../repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(chatServiceProvider));
});

final getConversationSummariesUseCaseProvider =
    Provider<GetConversationSummariesUseCase>((ref) {
  return GetConversationSummariesUseCase(ref.read(chatRepositoryProvider));
});

final getConversationMessagesUseCaseProvider =
    Provider<GetConversationMessagesUseCase>((ref) {
  return GetConversationMessagesUseCase(ref.read(chatRepositoryProvider));
});

final markConversationReadUseCaseProvider =
    Provider<MarkConversationReadUseCase>((ref) {
  return MarkConversationReadUseCase(ref.read(chatRepositoryProvider));
});

final setConversationPinnedUseCaseProvider =
    Provider<SetConversationPinnedUseCase>((ref) {
  return SetConversationPinnedUseCase(ref.read(chatRepositoryProvider));
});

class GetConversationSummariesUseCase {
  const GetConversationSummariesUseCase(this._repository);
  final ChatRepository _repository;

  Future<List<ChatThread>> call(String token) =>
      _repository.fetchThreads(token);
}

class GetConversationMessagesUseCase {
  const GetConversationMessagesUseCase(this._repository);
  final ChatRepository _repository;

  Future<List<ChatMessageModel>> call({
    required String token,
    required int peerId,
  }) =>
      _repository.fetchMessages(token: token, peerId: peerId);
}

class MarkConversationReadUseCase {
  const MarkConversationReadUseCase(this._repository);
  final ChatRepository _repository;

  Future<void> call({
    required String token,
    required int peerId,
  }) =>
      _repository.markConversationRead(token: token, peerId: peerId);
}

class SetConversationPinnedUseCase {
  const SetConversationPinnedUseCase(this._repository);
  final ChatRepository _repository;

  Future<void> call({
    required String token,
    required int peerId,
    required bool isPinned,
  }) =>
      _repository.setConversationPinned(
        token: token,
        peerId: peerId,
        isPinned: isPinned,
      );
}

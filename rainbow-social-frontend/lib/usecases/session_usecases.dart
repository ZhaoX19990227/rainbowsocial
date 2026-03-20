import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../providers/app_providers.dart';
import '../repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.read(sessionStorageProvider));
});

final saveSessionUseCaseProvider = Provider<SaveSessionUseCase>((ref) {
  return SaveSessionUseCase(ref.read(sessionRepositoryProvider));
});

final loadSessionUseCaseProvider = Provider<LoadSessionUseCase>((ref) {
  return LoadSessionUseCase(ref.read(sessionRepositoryProvider));
});

final clearSessionUseCaseProvider = Provider<ClearSessionUseCase>((ref) {
  return ClearSessionUseCase(ref.read(sessionRepositoryProvider));
});

class SaveSessionUseCase {
  const SaveSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call(AuthSession session) => _repository.save(session);
}

class LoadSessionUseCase {
  const LoadSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<AuthSession?> call() => _repository.load();
}

class ClearSessionUseCase {
  const ClearSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call() => _repository.clear();
}

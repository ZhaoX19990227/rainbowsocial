import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../providers/app_providers.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authServiceProvider));
});

final sendCodeUseCaseProvider = Provider<SendCodeUseCase>((ref) {
  return SendCodeUseCase(ref.read(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

class SendCodeUseCase {
  const SendCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendCode(email);
}

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call(String email, String code) =>
      _repository.login(email, code);

  AuthSession demoSession(String email) => _repository.demoSession(email);
}

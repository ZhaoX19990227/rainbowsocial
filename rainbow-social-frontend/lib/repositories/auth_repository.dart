import '../models/auth_session.dart';
import '../services/auth_service.dart';

class AuthRepository {
  const AuthRepository(this._service);

  final AuthService _service;

  Future<void> sendCode(String email) => _service.sendCode(email);

  Future<AuthSession> login(String email, String code) =>
      _service.login(email, code);

  AuthSession demoSession(String email) => _service.demoSession(email);
}

import '../models/auth_session.dart';
import '../services/auth_service.dart';

class AuthRepository {
  const AuthRepository(this._service);

  final AuthService _service;

  Future<void> register(String account, String password) =>
      _service.register(account, password);

  Future<AuthSession> login(String account, String password) =>
      _service.login(account, password);

  AuthSession demoSession(String account) => _service.demoSession(account);
}

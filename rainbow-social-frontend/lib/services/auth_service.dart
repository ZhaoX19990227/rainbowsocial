import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<void> register(String account, String password) async {
    await _client.post('/auth/register', body: {
      'account': account,
      'password': password,
    });
  }

  Future<AuthSession> login(String account, String password) async {
    final response = await _client.post('/auth/login', body: {
      'account': account,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    return AuthSession(
      token: '${data['token'] ?? ''}',
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'api_client.dart';
import 'app_flags.dart';
import 'mock_social_data.dart';

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

  AuthSession demoSession(String account) {
    if (!AppFlags.useMockFallbacks) {
      throw Exception('Mock fallback is disabled');
    }
    final user = MockSocialData.users.first.copyWith(
      id: 99,
      email: account,
      nickname: account,
      age: 0,
      heightCm: 0,
      weightKg: 0,
      birthday: '',
      zodiacSign: '',
      bio: '',
      tags: const [],
      positionRole: '',
      locationLabel: '',
    );
    return AuthSession(token: 'demo-token', user: user);
  }
}

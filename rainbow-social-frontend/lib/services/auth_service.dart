import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'api_client.dart';
import 'app_flags.dart';
import 'mock_social_data.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<void> sendCode(String email) async {
    await _client.post('/auth/send-code', body: {'email': email});
  }

  Future<AuthSession> login(String email, String code) async {
    final response = await _client.post('/auth/login', body: {
      'email': email,
      'code': code,
    });
    final data = response['data'] as Map<String, dynamic>;
    return AuthSession(
      token: '${data['token'] ?? ''}',
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  AuthSession demoSession(String email) {
    if (!AppFlags.useMockFallbacks) {
      throw Exception('Mock fallback is disabled');
    }
    final user = MockSocialData.users.first.copyWith(
      id: 99,
      email: email,
      nickname: 'You',
      age: 25,
      bio: 'A little mysterious, a little radiant.',
      tags: const ['Night walks', 'Coffee', 'Design'],
    );
    return AuthSession(token: 'demo-token', user: user);
  }
}

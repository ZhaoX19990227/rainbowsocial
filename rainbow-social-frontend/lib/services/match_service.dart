import '../models/match_user.dart';
import 'api_client.dart';
import 'app_flags.dart';
import 'mock_social_data.dart';

class MatchService {
  MatchService(this._client);

  final ApiClient _client;

  Future<List<MatchUser>> fetchMatches(String token) async {
    try {
      final response = await _client.get('/matches', token: token);
      final items = response['data'] as List<dynamic>;
      return items
          .map((item) => MatchUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      return MockSocialData.users
          .map(
            (user) => MatchUser(
              user: user,
              matchedAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
          )
          .toList();
    }
  }
}

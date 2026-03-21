import '../models/match_user.dart';
import '../models/match_summary.dart';
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

  Future<MatchSummary> fetchSummary(String token) async {
    try {
      final response = await _client.get('/matches/summary', token: token);
      return MatchSummary.fromJson(response['data'] as Map<String, dynamic>);
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      final mutual = MockSocialData.users
          .take(2)
          .map(
            (user) => MatchUser(
              user: user,
              matchedAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
          )
          .toList();
      final sent = MockSocialData.users
          .skip(1)
          .take(2)
          .map(
            (user) => LikeUser(
              user: user,
              likedAt: DateTime.now().subtract(const Duration(hours: 8)),
              isMutual: mutual.any((item) => item.user.id == user.id),
            ),
          )
          .toList();
      final received = MockSocialData.users
          .take(3)
          .map(
            (user) => LikeUser(
              user: user,
              likedAt: DateTime.now().subtract(const Duration(hours: 5)),
              isMutual: mutual.any((item) => item.user.id == user.id),
            ),
          )
          .toList();
      return MatchSummary(sent: sent, received: received, mutual: mutual);
    }
  }
}

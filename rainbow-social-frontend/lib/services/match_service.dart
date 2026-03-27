import '../models/match_user.dart';
import '../models/match_summary.dart';
import 'api_client.dart';

class MatchService {
  MatchService(this._client);

  final ApiClient _client;

  Future<List<MatchUser>> fetchMatches(String token) async {
    final response = await _client.get('/matches', token: token);
    final items = response['data'] as List<dynamic>;
    return items
        .map((item) => MatchUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MatchSummary> fetchSummary(String token) async {
    final response = await _client.get('/matches/summary', token: token);
    return MatchSummary.fromJson(response['data'] as Map<String, dynamic>);
  }
}

import '../models/match_user.dart';
import '../models/match_summary.dart';
import '../services/match_service.dart';

class MatchRepository {
  const MatchRepository(this._service);

  final MatchService _service;

  Future<List<MatchUser>> fetchMatches(String token) =>
      _service.fetchMatches(token);

  Future<MatchSummary> fetchSummary(String token) => _service.fetchSummary(token);
}

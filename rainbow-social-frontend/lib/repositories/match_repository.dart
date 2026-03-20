import '../models/match_user.dart';
import '../services/match_service.dart';

class MatchRepository {
  const MatchRepository(this._service);

  final MatchService _service;

  Future<List<MatchUser>> fetchMatches(String token) =>
      _service.fetchMatches(token);
}

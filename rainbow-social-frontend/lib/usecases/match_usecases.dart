import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_user.dart';
import '../models/match_summary.dart';
import '../providers/app_providers.dart';
import '../repositories/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.read(matchServiceProvider));
});

final getMatchesUseCaseProvider = Provider<GetMatchesUseCase>((ref) {
  return GetMatchesUseCase(ref.read(matchRepositoryProvider));
});

final getMatchSummaryUseCaseProvider = Provider<GetMatchSummaryUseCase>((ref) {
  return GetMatchSummaryUseCase(ref.read(matchRepositoryProvider));
});

class GetMatchesUseCase {
  const GetMatchesUseCase(this._repository);
  final MatchRepository _repository;

  Future<List<MatchUser>> call(String token) => _repository.fetchMatches(token);
}

class GetMatchSummaryUseCase {
  const GetMatchSummaryUseCase(this._repository);
  final MatchRepository _repository;

  Future<MatchSummary> call(String token) => _repository.fetchSummary(token);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../repositories/swipe_repository.dart';
import '../services/swipe_service.dart';

final swipeRepositoryProvider = Provider<SwipeRepository>((ref) {
  return SwipeRepository(ref.read(swipeServiceProvider));
});

final getRecommendationsUseCaseProvider =
    Provider<GetRecommendationsUseCase>((ref) {
  return GetRecommendationsUseCase(ref.read(swipeRepositoryProvider));
});

final likeUserUseCaseProvider = Provider<LikeUserUseCase>((ref) {
  return LikeUserUseCase(ref.read(swipeRepositoryProvider));
});

final passUserUseCaseProvider = Provider<PassUserUseCase>((ref) {
  return PassUserUseCase(ref.read(swipeRepositoryProvider));
});

class GetRecommendationsUseCase {
  const GetRecommendationsUseCase(this._repository);
  final SwipeRepository _repository;

  Future<List<AppUser>> call(String token) =>
      _repository.getRecommendations(token);
}

class LikeUserUseCase {
  const LikeUserUseCase(this._repository);
  final SwipeRepository _repository;

  Future<SwipeResult> call(String token, int targetUserId) =>
      _repository.like(token, targetUserId);
}

class PassUserUseCase {
  const PassUserUseCase(this._repository);
  final SwipeRepository _repository;

  Future<SwipeResult> call(String token, int targetUserId) =>
      _repository.pass(token, targetUserId);
}

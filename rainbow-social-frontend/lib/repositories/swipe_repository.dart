import '../models/app_user.dart';
import '../services/swipe_service.dart';

class SwipeRepository {
  const SwipeRepository(this._service);

  final SwipeService _service;

  Future<List<AppUser>> getRecommendations(String token) =>
      _service.getRecommendations(token);

  Future<SwipeResult> like(String token, int targetUserId) =>
      _service.like(token, targetUserId);

  Future<SwipeResult> pass(String token, int targetUserId) =>
      _service.pass(token, targetUserId);
}

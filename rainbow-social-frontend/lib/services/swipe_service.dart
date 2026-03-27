import '../models/app_user.dart';
import 'api_client.dart';

class SwipeResult {
  const SwipeResult({required this.action, required this.matched});

  final String action;
  final bool matched;
}

class SwipeService {
  SwipeService(this._client);

  final ApiClient _client;

  Future<List<AppUser>> getRecommendations(String token) async {
    final response = await _client.get('/recommendations', token: token);
    final items = response['data'] as List<dynamic>;
    return items
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SwipeResult> like(String token, int targetUserId) async {
    final response = await _client.post(
      '/swipe/like',
      token: token,
      body: {'target_user_id': targetUserId},
    );
    final data = response['data'] as Map<String, dynamic>;
    return SwipeResult(
      action: '${data['action'] ?? 'like'}',
      matched: data['matched'] == true,
    );
  }

  Future<SwipeResult> pass(String token, int targetUserId) async {
    final response = await _client.post(
      '/swipe/pass',
      token: token,
      body: {'target_user_id': targetUserId},
    );
    final data = response['data'] as Map<String, dynamic>;
    return SwipeResult(
      action: '${data['action'] ?? 'pass'}',
      matched: data['matched'] == true,
    );
  }

  Future<void> undo(String token, int targetUserId) async {
    await _client.post(
      '/swipe/undo',
      token: token,
      body: {'target_user_id': targetUserId},
    );
  }
}

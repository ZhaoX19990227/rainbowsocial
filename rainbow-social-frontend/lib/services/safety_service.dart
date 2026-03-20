import 'api_client.dart';

class SafetyService {
  SafetyService(this._client);

  final ApiClient _client;

  Future<void> report({
    required String token,
    required int reportedUserId,
    required String reason,
    String details = '',
  }) async {
    await _client.post(
      '/report',
      token: token,
      body: {
        'reported_user_id': reportedUserId,
        'reason': reason,
        'details': details,
      },
    );
  }

  Future<void> block({
    required String token,
    required int blockedUserId,
    String reason = '',
  }) async {
    await _client.post(
      '/block',
      token: token,
      body: {
        'blocked_user_id': blockedUserId,
        'reason': reason,
      },
    );
  }
}

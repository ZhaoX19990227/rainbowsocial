import 'api_client.dart';
import '../models/block_status.dart';

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

  Future<void> unblock({
    required String token,
    required int blockedUserId,
  }) async {
    await _client.delete(
      '/block',
      token: token,
      body: {
        'blocked_user_id': blockedUserId,
      },
    );
  }

  Future<BlockStatus> getBlockStatus({
    required String token,
    required int targetUserId,
  }) async {
    final response = await _client.get(
      '/block/$targetUserId/status',
      token: token,
    );
    return BlockStatus.fromJson(response['data'] as Map<String, dynamic>);
  }
}

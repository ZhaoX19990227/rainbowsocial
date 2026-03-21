import '../services/safety_service.dart';
import '../models/block_status.dart';

class SafetyRepository {
  const SafetyRepository(this._service);

  final SafetyService _service;

  Future<void> report({
    required String token,
    required int reportedUserId,
    required String reason,
    String details = '',
  }) =>
      _service.report(
        token: token,
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
      );

  Future<void> block({
    required String token,
    required int blockedUserId,
    String reason = '',
  }) =>
      _service.block(
        token: token,
        blockedUserId: blockedUserId,
        reason: reason,
      );

  Future<void> unblock({
    required String token,
    required int blockedUserId,
  }) =>
      _service.unblock(
        token: token,
        blockedUserId: blockedUserId,
      );

  Future<BlockStatus> getBlockStatus({
    required String token,
    required int targetUserId,
  }) =>
      _service.getBlockStatus(
        token: token,
        targetUserId: targetUserId,
      );
}

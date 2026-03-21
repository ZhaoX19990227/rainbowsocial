import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/block_status.dart';
import '../providers/app_providers.dart';
import '../repositories/safety_repository.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(ref.read(safetyServiceProvider));
});

final reportUserUseCaseProvider = Provider<ReportUserUseCase>((ref) {
  return ReportUserUseCase(ref.read(safetyRepositoryProvider));
});

final blockUserUseCaseProvider = Provider<BlockUserUseCase>((ref) {
  return BlockUserUseCase(ref.read(safetyRepositoryProvider));
});

final unblockUserUseCaseProvider = Provider<UnblockUserUseCase>((ref) {
  return UnblockUserUseCase(ref.read(safetyRepositoryProvider));
});

final getBlockStatusUseCaseProvider = Provider<GetBlockStatusUseCase>((ref) {
  return GetBlockStatusUseCase(ref.read(safetyRepositoryProvider));
});

class ReportUserUseCase {
  const ReportUserUseCase(this._repository);
  final SafetyRepository _repository;

  Future<void> call({
    required String token,
    required int reportedUserId,
    required String reason,
    String details = '',
  }) =>
      _repository.report(
        token: token,
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
      );
}

class BlockUserUseCase {
  const BlockUserUseCase(this._repository);
  final SafetyRepository _repository;

  Future<void> call({
    required String token,
    required int blockedUserId,
    String reason = '',
  }) =>
      _repository.block(
        token: token,
        blockedUserId: blockedUserId,
        reason: reason,
      );
}

class UnblockUserUseCase {
  const UnblockUserUseCase(this._repository);
  final SafetyRepository _repository;

  Future<void> call({
    required String token,
    required int blockedUserId,
  }) =>
      _repository.unblock(
        token: token,
        blockedUserId: blockedUserId,
      );
}

class GetBlockStatusUseCase {
  const GetBlockStatusUseCase(this._repository);
  final SafetyRepository _repository;

  Future<BlockStatus> call({
    required String token,
    required int targetUserId,
  }) =>
      _repository.getBlockStatus(
        token: token,
        targetUserId: targetUserId,
      );
}

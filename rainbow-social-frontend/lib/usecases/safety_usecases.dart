import 'package:flutter_riverpod/flutter_riverpod.dart';

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

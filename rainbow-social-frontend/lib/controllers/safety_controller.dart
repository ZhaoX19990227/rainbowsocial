import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/block_status.dart';
import '../usecases/safety_usecases.dart';
import 'auth_controller.dart';

final safetyControllerProvider =
    StateNotifierProvider<SafetyController, AsyncValue<void>>((ref) {
  return SafetyController(ref);
});

class SafetyController extends StateNotifier<AsyncValue<void>> {
  SafetyController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> report({
    required int userId,
    required String reason,
    String details = '',
  }) async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return _ref.read(reportUserUseCaseProvider)(
        token: session.token,
        reportedUserId: userId,
        reason: reason,
        details: details,
      );
    });
  }

  Future<void> block({
    required int userId,
    String reason = '',
  }) async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return _ref.read(blockUserUseCaseProvider)(
        token: session.token,
        blockedUserId: userId,
        reason: reason,
      );
    });
  }

  Future<void> unblock({
    required int userId,
  }) async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return _ref.read(unblockUserUseCaseProvider)(
        token: session.token,
        blockedUserId: userId,
      );
    });
  }
}

final blockStatusProvider =
    FutureProvider.autoDispose.family<BlockStatus, int>((ref, userId) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) {
    return const BlockStatus.none();
  }
  return ref.read(getBlockStatusUseCaseProvider)(
        token: session.token,
        targetUserId: userId,
      );
});

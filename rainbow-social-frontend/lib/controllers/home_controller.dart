import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/defaults.dart';
import '../usecases/swipe_usecases.dart';
import '../usecases/user_usecases.dart';
import 'auth_controller.dart';
import 'profile_controller.dart';

final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<List<AppUser>>>((ref) {
  return HomeController(ref);
});

class HomeController extends StateNotifier<AsyncValue<List<AppUser>>> {
  HomeController(this._ref) : super(const AsyncValue.loading()) {
    loadRecommendations();
  }

  final Ref _ref;
  _SwipeHistoryEntry? _lastSwipe;

  bool get canUndo => _lastSwipe != null;

  Future<void> loadRecommendations() async {
    var session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = const AsyncValue.data([]);
      return;
    }

    if (session.user.lat == 0 && session.user.lng == 0) {
      final bootstrappedUser = await _ref.read(updateProfileUseCaseProvider)(
        session.token,
        session.user.copyWith(
          lat: Defaults.fallbackLat,
          lng: Defaults.fallbackLng,
          avatar: session.user.avatarOrFallback,
        ),
      );
      _ref
          .read(authControllerProvider.notifier)
          .updateSessionUser(bootstrappedUser);
      session = _ref.read(authControllerProvider).valueOrNull;
      _ref.invalidate(profileControllerProvider);
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return _ref.read(getRecommendationsUseCaseProvider)(session!.token);
    });
  }

  Future<HomeSwipeResult?> likeTopCard() async {
    final users = [...(state.valueOrNull ?? const <AppUser>[])];
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null || users.isEmpty) return null;

    final top = users.removeAt(0);
    state = AsyncValue.data(users);
    final result =
        await _ref.read(likeUserUseCaseProvider)(session.token, top.id);
    _lastSwipe = _SwipeHistoryEntry(user: top);
    return HomeSwipeResult(
      user: top,
      matched: result.matched,
    );
  }

  Future<HomeSwipeResult?> passTopCard() async {
    final users = [...(state.valueOrNull ?? const <AppUser>[])];
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null || users.isEmpty) return null;

    final top = users.removeAt(0);
    state = AsyncValue.data(users);
    await _ref.read(passUserUseCaseProvider)(session.token, top.id);
    _lastSwipe = _SwipeHistoryEntry(user: top);
    return HomeSwipeResult(user: top, matched: false);
  }

  Future<AppUser?> undoLastSwipe() async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    final lastSwipe = _lastSwipe;
    if (session == null || lastSwipe == null) return null;

    await _ref.read(undoSwipeUseCaseProvider)(session.token, lastSwipe.user.id);
    final users = [...(state.valueOrNull ?? const <AppUser>[])];
    state = AsyncValue.data([lastSwipe.user, ...users]);
    _lastSwipe = null;
    return lastSwipe.user;
  }
}

class HomeSwipeResult {
  const HomeSwipeResult({
    required this.user,
    required this.matched,
  });

  final AppUser user;
  final bool matched;
}

class _SwipeHistoryEntry {
  const _SwipeHistoryEntry({
    required this.user,
  });

  final AppUser user;
}

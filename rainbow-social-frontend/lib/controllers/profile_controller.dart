import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/defaults.dart';
import '../usecases/user_usecases.dart';
import 'auth_controller.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<AppUser?>>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<AsyncValue<AppUser?>> {
  ProfileController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = await AsyncValue.guard(
      () => _ref.read(getProfileUseCaseProvider)(session.token),
    );
  }

  Future<void> save(AppUser user) async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedUser = await _ref.read(updateProfileUseCaseProvider)(
        session.token,
        user.copyWith(
          lat: user.lat == 0 ? Defaults.fallbackLat : user.lat,
          lng: user.lng == 0 ? Defaults.fallbackLng : user.lng,
          avatar: user.avatarOrFallback,
        ),
      );
      _ref.read(authControllerProvider.notifier).updateSessionUser(updatedUser);
      return updatedUser;
    });
  }
}

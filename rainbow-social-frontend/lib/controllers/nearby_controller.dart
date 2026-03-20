import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/defaults.dart';
import '../usecases/user_usecases.dart';
import 'auth_controller.dart';

final nearbyControllerProvider =
    StateNotifierProvider<NearbyController, AsyncValue<List<AppUser>>>((ref) {
  return NearbyController(ref);
});

class NearbyController extends StateNotifier<AsyncValue<List<AppUser>>> {
  NearbyController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return _ref.read(getNearbyUsersUseCaseProvider)(
        session.token,
        lat: session.user.lat == 0 ? Defaults.fallbackLat : session.user.lat,
        lng: session.user.lng == 0 ? Defaults.fallbackLng : session.user.lng,
      );
    });
  }
}

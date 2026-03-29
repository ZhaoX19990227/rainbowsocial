import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/nearby_filter.dart';
import '../providers/app_providers.dart';
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

  Future<void> load({
    NearbyFilter filter = const NearbyFilter(),
    bool useDeviceLocation = false,
  }) async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = const AsyncValue.data([]);
      return;
    }

    var lat = session.user.lat == 0 ? Defaults.fallbackLat : session.user.lat;
    var lng = session.user.lng == 0 ? Defaults.fallbackLng : session.user.lng;
    if (useDeviceLocation) {
      try {
        final position =
            await _ref.read(locationServiceProvider).getCurrentPosition();
        lat = position.latitude;
        lng = position.longitude;
        final locationLabel = await _ref.read(locationLabelServiceProvider).getLocationLabel(
              lat: lat,
              lng: lng,
            );
        final updatedUser = await _ref.read(updateLocationUseCaseProvider)(
          session.token,
          lat: lat,
          lng: lng,
          locationLabel: locationLabel,
        );
        _ref.read(authControllerProvider.notifier).updateSessionUser(updatedUser);
      } catch (_) {
        // fall back to saved location
      }
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return _ref.read(getNearbyUsersUseCaseProvider)(
        session.token,
        lat: lat,
        lng: lng,
        filter: filter,
      );
    });
  }
}

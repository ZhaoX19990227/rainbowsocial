import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_user.dart';
import '../usecases/match_usecases.dart';
import 'auth_controller.dart';

final matchesControllerProvider =
    StateNotifierProvider<MatchesController, AsyncValue<List<MatchUser>>>(
        (ref) {
  return MatchesController(ref);
});

class MatchesController extends StateNotifier<AsyncValue<List<MatchUser>>> {
  MatchesController(this._ref) : super(const AsyncValue.loading()) {
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
      return _ref.read(getMatchesUseCaseProvider)(session.token);
    });
  }
}

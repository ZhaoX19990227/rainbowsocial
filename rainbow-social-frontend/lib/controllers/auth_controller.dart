import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../usecases/auth_usecases.dart';
import '../usecases/session_usecases.dart';
import '../usecases/user_usecases.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    restoreSession();
  }

  final Ref _ref;

  Future<void> restoreSession() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async {
        final savedSession = await _ref.read(loadSessionUseCaseProvider)();
        if (savedSession == null) {
          return null;
        }
        if (savedSession.token.isEmpty) {
          await _ref.read(clearSessionUseCaseProvider)();
          return null;
        }
        try {
          final user =
              await _ref.read(getProfileUseCaseProvider)(savedSession.token);
          final refreshedSession =
              AuthSession(token: savedSession.token, user: user);
          await _ref.read(saveSessionUseCaseProvider)(refreshedSession);
          return refreshedSession;
        } on ApiException catch (error) {
          if (error.statusCode == 401) {
            await _ref.read(clearSessionUseCaseProvider)();
            return null;
          }
          rethrow;
        }
      },
    );
  }

  Future<void> register(String account, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(registerUseCaseProvider)(account, password);
      return state.valueOrNull;
    });
  }

  Future<void> login(String account, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final session = await _ref.read(loginUseCaseProvider)(account, password);
      await _ref.read(saveSessionUseCaseProvider)(session);
      return session;
    });
  }

  Future<void> signOut() async {
    await _ref.read(clearSessionUseCaseProvider)();
    state = const AsyncValue.data(null);
  }

  void updateSessionUser(AppUser user) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = AuthSession(token: current.token, user: user);
    state = AsyncValue.data(updated);
    _ref.read(saveSessionUseCaseProvider)(updated);
  }
}

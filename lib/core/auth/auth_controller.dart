import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController({
    required AuthSessionStore sessionStore,
    AuthSession? initialSession,
  })  : _sessionStore = sessionStore,
        super(AsyncValue.data(initialSession));

  final AuthSessionStore _sessionStore;

  AuthSession? get session => state.valueOrNull;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_sessionStore.restore);
  }

  Future<void> setSession(AuthSession session) async {
    await _sessionStore.save(session);
    state = AsyncValue.data(session);
  }

  Future<void> clearSession() async {
    await _sessionStore.clear();
    state = const AsyncValue.data(null);
  }
}

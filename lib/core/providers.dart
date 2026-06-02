import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_session.dart';
import 'network/api_client.dart';
import 'storage/key_value_storage.dart';
import 'storage/secure_key_value_storage.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final secureStorageProvider = Provider<KeyValueStorage>(
  (ref) => SecureKeyValueStorage(),
);

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => AuthSessionStore(ref.watch(secureStorageProvider)),
);

final initialAuthSessionProvider = Provider<AuthSession?>((ref) => null);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(
    sessionStore: ref.watch(authSessionStoreProvider),
    initialSession: ref.watch(initialAuthSessionProvider),
  );
});

final dioProvider = Provider<Dio>(
  (ref) => ref.watch(apiClientProvider).dio,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final authController = ref.read(authControllerProvider.notifier);
  return ApiClient(
    config: ref.watch(appConfigProvider),
    tokenProvider: () async => authController.session?.token,
    onUnauthorized: authController.clearSession,
  );
});

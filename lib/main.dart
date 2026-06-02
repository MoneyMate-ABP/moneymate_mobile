import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/moneymate_app.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'core/storage/secure_key_value_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final sessionStore = AuthSessionStore(SecureKeyValueStorage());
  final initialSession = await sessionStore.restore();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authSessionStoreProvider.overrideWithValue(sessionStore),
        initialAuthSessionProvider.overrideWithValue(initialSession),
      ],
      child: const MoneyMateApp(),
    ),
  );
}

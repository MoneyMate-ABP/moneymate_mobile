import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/app/moneymate_app.dart';
import 'package:moneymate_mobile/core/auth/auth_session.dart';
import 'package:moneymate_mobile/core/config/app_config.dart';
import 'package:moneymate_mobile/core/providers.dart';
import 'package:moneymate_mobile/core/storage/key_value_storage.dart';

class MemoryStorage implements KeyValueStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

void main() {
  testWidgets('shows auth placeholder when no session is restored',
      (tester) async {
    final sessionStore = AuthSessionStore(MemoryStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(apiBaseUrl: 'https://api.test'),
          ),
          authSessionStoreProvider.overrideWithValue(sessionStore),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
        child: const MoneyMateApp(),
      ),
    );

    expect(find.text('Masuk ke MoneyMate'), findsOneWidget);
  });

  testWidgets('shows dashboard placeholder when session is restored',
      (tester) async {
    final sessionStore = AuthSessionStore(MemoryStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(apiBaseUrl: 'https://api.test'),
          ),
          authSessionStoreProvider.overrideWithValue(sessionStore),
          initialAuthSessionProvider.overrideWithValue(
            const AuthSession(
              token: 'jwt-token',
              user: AuthUser(
                id: 1,
                name: 'Bintang',
                email: 'bintang@test.dev',
              ),
            ),
          ),
        ],
        child: const MoneyMateApp(),
      ),
    );

    expect(find.text('MoneyMate Dashboard'), findsOneWidget);
  });
}

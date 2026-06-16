import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/app/moneymate_app.dart';
import 'package:moneymate_mobile/core/auth/auth_session.dart';
import 'package:moneymate_mobile/core/config/app_config.dart';
import 'package:moneymate_mobile/core/providers.dart';
import 'package:moneymate_mobile/core/storage/key_value_storage.dart';
import 'package:moneymate_mobile/core/network/api_client.dart';

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
  late ApiClient fakeApiClient;

  setUp(() {
    fakeApiClient = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.test'),
      tokenProvider: () async => 'jwt-token',
      transport: (request) async {
        final path = request.uri.path;
        if (path.endsWith('/api/dashboard')) {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'totals': {'balance': 0.0, 'income': 0.0, 'expense': 0.0},
              'budgets': {'spentToday': 0.0, 'remainingToday': 0.0},
              'recentTransactions': [],
              'activeBudgets': []
            },
          );
        } else if (path.endsWith('/api/categories')) {
          return const ApiResponse(
            statusCode: 200,
            body: [],
          );
        } else if (path.endsWith('/api/budget-periods')) {
          return const ApiResponse(
            statusCode: 200,
            body: {'data': []},
          );
        } else if (path.endsWith('/api/transactions')) {
          return const ApiResponse(
            statusCode: 200,
            body: {'data': []},
          );
        }
        return const ApiResponse(statusCode: 200, body: {});
      },
    );
  });

  testWidgets('shows auth placeholder when no session is restored',
      (tester) async {
    final sessionStore = AuthSessionStore(MemoryStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(apiBaseUrl: 'https://api.test'),
          ),
          apiClientProvider.overrideWithValue(fakeApiClient),
          authSessionStoreProvider.overrideWithValue(sessionStore),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
        child: const MoneyMateApp(),
      ),
    );

    expect(find.text('MoneyMate'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
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
          apiClientProvider.overrideWithValue(fakeApiClient),
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

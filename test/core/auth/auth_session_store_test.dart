import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/core/auth/auth_session.dart';
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
  test('save persists token and user then restore returns authenticated session',
      () async {
    final storage = MemoryStorage();
    final store = AuthSessionStore(storage);
    const user = AuthUser(id: 7, name: 'Bintang', email: 'bintang@test.dev');

    await store.save(const AuthSession(token: 'jwt-token', user: user));

    final restored = await store.restore();
    expect(restored?.token, 'jwt-token');
    expect(restored?.user, user);
  });

  test('clear removes token and user from storage', () async {
    final storage = MemoryStorage();
    final store = AuthSessionStore(storage);

    await store.save(
      const AuthSession(
        token: 'jwt-token',
        user: AuthUser(id: 1, name: 'Nathan', email: 'nathan@test.dev'),
      ),
    );
    await store.clear();

    expect(await store.restore(), isNull);
    expect(storage.values, isEmpty);
  });
}

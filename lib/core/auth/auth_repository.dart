import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

class AuthRepository {
  AuthRepository();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final user = AuthUser(id: 1, name: email.split('@').first, email: email);

    return AuthSession(token: 'mock-token', user: user);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final user = AuthUser(id: 1, name: name, email: email);

    return AuthSession(token: 'mock-token', user: user);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

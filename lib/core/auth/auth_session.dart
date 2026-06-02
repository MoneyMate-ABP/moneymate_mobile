import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../storage/key_value_storage.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return AuthUser(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
    );
  }

  final int id;
  final String name;
  final String email;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [id, name, email];
}

class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;

  @override
  List<Object?> get props => [token, user];
}

class AuthSessionStore {
  AuthSessionStore(this._storage);

  static const _tokenKey = 'moneymate.auth.token';
  static const _userKey = 'moneymate.auth.user';

  final KeyValueStorage _storage;

  Future<AuthSession?> restore() async {
    final token = await _storage.read(_tokenKey);
    final rawUser = await _storage.read(_userKey);

    if (token == null || token.isEmpty || rawUser == null || rawUser.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawUser);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return AuthSession(
      token: token,
      user: AuthUser.fromJson(decoded),
    );
  }

  Future<void> save(AuthSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userKey, value: jsonEncode(session.user));
  }

  Future<void> clear() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_userKey);
  }
}

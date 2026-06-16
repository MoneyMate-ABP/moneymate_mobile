import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../providers.dart';
import 'auth_session.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    if (response.body is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons autentikasi tidak valid.',
      );
    }

    final body = response.body as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Data autentikasi tidak ditemukan.',
      );
    }

    final token = data['token'] as String?;
    final userJson = data['user'];
    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons login tidak lengkap.',
      );
    }

    final user = AuthUser.fromJson(userJson);
    return AuthSession(token: token, user: user);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );

    if (response.body is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons registrasi tidak valid.',
      );
    }

    final body = response.body as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Data registrasi tidak ditemukan.',
      );
    }

    final token = data['token'] as String?;
    final userJson = data['user'];
    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons registrasi tidak lengkap.',
      );
    }

    final user = AuthUser.fromJson(userJson);
    return AuthSession(token: token, user: user);
  }

  Future<AuthSession> loginWithGoogleToken({
    required String idToken,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/google',
      body: {'idToken': idToken},
    );

    if (response.body is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons autentikasi Google tidak valid.',
      );
    }

    final body = response.body as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Data autentikasi Google tidak ditemukan.',
      );
    }

    final token = data['token'] as String?;
    final userJson = data['user'];
    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons Google login tidak lengkap.',
      );
    }

    final user = AuthUser.fromJson(userJson);
    return AuthSession(token: token, user: user);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

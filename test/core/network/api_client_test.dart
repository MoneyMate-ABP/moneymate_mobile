import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/core/network/api_client.dart';

void main() {
  test('request injects bearer token from token provider', () async {
    late ApiRequest capturedRequest;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.test'),
      tokenProvider: () async => 'jwt-token',
      transport: (request) async {
        capturedRequest = request;
        return const ApiResponse(statusCode: 200, body: '{"ok":true}');
      },
    );

    await client.get('/api/dashboard');

    expect(capturedRequest.uri.toString(), 'https://api.test/api/dashboard');
    expect(capturedRequest.headers['Authorization'], 'Bearer jwt-token');
  });

  test('request calls unauthorized handler when backend returns 401', () async {
    var unauthorizedCalled = false;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.test/'),
      tokenProvider: () async => 'expired-token',
      onUnauthorized: () async {
        unauthorizedCalled = true;
      },
      transport: (_) async => const ApiResponse(statusCode: 401, body: '{}'),
    );

    final response = await client.get('/api/dashboard');

    expect(response.statusCode, 401);
    expect(unauthorizedCalled, isTrue);
  });

  test('request skips authorization header when token is unavailable', () async {
    late ApiRequest capturedRequest;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.test'),
      tokenProvider: () async => null,
      transport: (request) async {
        capturedRequest = request;
        return const ApiResponse(statusCode: 200, body: '{}');
      },
    );

    await client.post('/api/auth/login', body: {'email': 'a@test.dev'});

    expect(capturedRequest.headers.containsKey('Authorization'), isFalse);
    expect(capturedRequest.headers['Content-Type'], 'application/json');
  });

  test('request skips authorization header for auth endpoints', () async {
    late ApiRequest capturedRequest;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.test'),
      tokenProvider: () async => 'stale-token',
      transport: (request) async {
        capturedRequest = request;
        return const ApiResponse(statusCode: 200, body: '{}');
      },
    );

    await client.post('/api/auth/login', body: {'email': 'a@test.dev'});

    expect(capturedRequest.headers.containsKey('Authorization'), isFalse);
    expect(capturedRequest.headers['Content-Type'], 'application/json');
  });
}

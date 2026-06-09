import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

export '../config/app_config.dart';

typedef TokenProvider = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();
typedef ApiTransport = Future<ApiResponse> Function(ApiRequest request);

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final Object? body;
  final Map<String, String> headers;
}

class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenProvider tokenProvider,
    UnauthorizedHandler? onUnauthorized,
    Dio? dio,
    ApiTransport? transport,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized,
        _transport = transport,
        dio = dio ?? _createDio(config) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              options.headers['Content-Type'] = 'application/json';
              options.headers['Accept'] = 'application/json';

              final token = await _tokenProvider();
              final path = options.uri.path;
              if (token != null &&
                  token.isNotEmpty &&
                  !_isAuthEndpoint(path)) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
            onError: (error, handler) async {
              if (error.response?.statusCode == 401) {
                await _onUnauthorized?.call();
              }
              handler.next(error);
            },
          ),
        );
  }

  final AppConfig _config;
  final TokenProvider _tokenProvider;
  final UnauthorizedHandler? _onUnauthorized;
  final ApiTransport? _transport;
  final Dio dio;

  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) {
    return request(
      'GET',
      path,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, Object?> queryParameters = const {},
  }) {
    return request(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, Object?> queryParameters = const {},
  }) {
    return request(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> delete(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) {
    return request(
      'DELETE',
      path,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> request(
    String method,
    String path, {
    Object? body,
    Map<String, Object?> queryParameters = const {},
  }) async {
    if (_transport != null) {
      final request = await _buildTestRequest(
        method,
        path,
        body: body,
        queryParameters: queryParameters,
      );
      final response = await _transport(request);
      if (response.statusCode == 401) {
        await _onUnauthorized?.call();
      }
      return response;
    }

    try {
      final response = await dio.request<Object?>(
        path,
        data: body,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(method: method.toUpperCase()),
      );
      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        body: response.data,
        headers: response.headers.map.map(
          (key, value) => MapEntry(key, value.join(',')),
        ),
      );
    } on DioException catch (error) {
      throw ApiException(
        statusCode: error.response?.statusCode,
        message: _extractErrorMessage(error),
        data: error.response?.data,
      );
    }
  }

  Future<ApiRequest> _buildTestRequest(
    String method,
    String path, {
    Object? body,
    Map<String, Object?> queryParameters = const {},
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty && !_isAuthEndpoint(uri.path)) {
      headers['Authorization'] = 'Bearer $token';
    }

    return ApiRequest(
      method: method.toUpperCase(),
      uri: uri,
      headers: headers,
      body: body,
    );
  }

  Uri _buildUri(String path, Map<String, Object?> queryParameters) {
    final base = Uri.parse(_config.apiBaseUrl);
    final normalizedBasePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters.map((key, value) => MapEntry(key, '$value')),
    );
  }

  static Dio _createDio(AppConfig config) {
    return Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
  }

  static bool _isAuthEndpoint(String path) {
    return path.startsWith('/api/auth/');
  }

  static String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return '${data['message']}';
    }
    return error.message ?? 'Request gagal.';
  }
}

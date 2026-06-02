class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  final int? statusCode;
  final String message;
  final Object? data;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

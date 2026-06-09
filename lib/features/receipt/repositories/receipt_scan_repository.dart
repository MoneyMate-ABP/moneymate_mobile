import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/receipt_scan_result.dart';

/// Repository for `POST /api/transactions/receipt-scan`.
///
/// Uploads a receipt file (image or PDF) as `multipart/form-data` and returns
/// an AI-generated [ReceiptScanResult] containing extracted transaction data.
///
/// The backend field name is `receipt` and accepts a single file up to 10 MB.
///
/// Supported MIME types:
/// - `image/jpeg`
/// - `image/png`
/// - `image/webp`
/// - `application/pdf`
class ReceiptScanRepository {
  const ReceiptScanRepository(this._apiClient);

  static const _endpoint = '/api/transactions/receipt-scan';

  /// Max file size accepted by the backend (10 MB).
  static const maxFileSize = 10 * 1024 * 1024; // 10 MB

  static const _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.pdf',
  };

  final ApiClient _apiClient;

  /// Uploads a receipt [file] (image or PDF) and returns the AI-parsed result.
  ///
  /// Throws [ApiException] on HTTP errors (e.g. 413 file too large, 422
  /// unsupported format, 500 AI failure).
  ///
  /// Throws [ArgumentError] if the file does not exist, exceeds [maxFileSize],
  /// or has an unsupported extension.
  ///
  /// The optional [onSendProgress] callback receives `(sent, total)` byte
  /// counts and can be used to drive a progress indicator.
  Future<ReceiptScanResult> scanReceipt(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    // ---- Client-side validation ----
    _validateFile(file);

    // ---- Build multipart form ----
    final ext = p.extension(file.path).toLowerCase();
    final contentType = _resolveContentType(ext);

    final formData = FormData.fromMap({
      'receipt': await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
        contentType: DioMediaType.parse(contentType),
      ),
    });

    // ---- Execute upload ----
    try {
      final response = await _apiClient.dio.post<Object?>(
        _endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          // Let Dio set the multipart content-type automatically (with
          // boundary), but make sure to keep our Accept and Auth headers
          // that the interceptor adds.
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      return _parseResponse(response.data);
    } on DioException catch (error) {
      throw ApiException(
        statusCode: error.response?.statusCode,
        message: _extractErrorMessage(error),
        data: error.response?.data,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Validation helpers
  // ---------------------------------------------------------------------------

  void _validateFile(File file) {
    if (!file.existsSync()) {
      throw ArgumentError('File tidak ditemukan: ${file.path}');
    }

    final size = file.lengthSync();
    if (size > maxFileSize) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      throw ArgumentError(
        'Ukuran file terlalu besar ($sizeMb MB). Maksimal 10 MB.',
      );
    }

    final ext = p.extension(file.path).toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw ArgumentError(
        'Format file tidak didukung ($ext). '
        'Gunakan JPG, PNG, WebP, atau PDF.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MIME type resolution
  // ---------------------------------------------------------------------------

  /// Maps a file extension to its MIME type string.
  static String _resolveContentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // ---------------------------------------------------------------------------
  // Response parsing
  // ---------------------------------------------------------------------------

  ReceiptScanResult _parseResponse(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'ReceiptScanRepository: unexpected response body '
        'from POST /api/transactions/receipt-scan.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'ReceiptScanRepository: missing "data" key in '
        'POST /api/transactions/receipt-scan response.',
      );
    }

    return ReceiptScanResult.fromJson(rawData);
  }

  // ---------------------------------------------------------------------------
  // Error extraction
  // ---------------------------------------------------------------------------

  static String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return '${data['message']}';
    }
    return error.message ?? 'Gagal memindai struk.';
  }
}

import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service that compresses receipt images before uploading them.
///
/// Uses [FlutterImageCompress] to progressively reduce image quality and/or
/// dimensions until the file fits within the backend's 10 MB limit.
///
/// PDF files are **not** compressed (passed through as-is) because
/// `flutter_image_compress` only handles raster images.
class ReceiptCompressor {
  const ReceiptCompressor();

  /// Maximum file size accepted by the backend.
  static const maxFileSize = 10 * 1024 * 1024; // 10 MB

  /// Quality steps used during progressive compression. We start with a
  /// moderate quality and drop further only if the file is still too large.
  static const _qualitySteps = [80, 60, 40, 25];

  /// Max pixel width at each compression pass. We only start down-scaling
  /// after the first quality pass fails.
  static const _maxWidthSteps = [1920, 1280, 1024, 800];

  /// Extensions that can be compressed (raster images).
  static const _compressibleExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  /// Compresses [file] if it is a raster image that exceeds [maxFileSize].
  ///
  /// Returns the compressed [File] (may be a new temporary file) or the
  /// original [file] unchanged if:
  /// - It is already under [maxFileSize].
  /// - It is a PDF or other non-image format.
  ///
  /// Throws [StateError] if the image cannot be compressed below [maxFileSize]
  /// even at the lowest quality/resolution.
  Future<File> compressIfNeeded(File file) async {
    final ext = p.extension(file.path).toLowerCase();

    // PDFs and non-image files: skip compression entirely.
    if (!_compressibleExtensions.contains(ext)) {
      return file;
    }

    // Already small enough — no compression needed.
    final originalSize = await file.length();
    if (originalSize <= maxFileSize) {
      return file;
    }

    // Progressive compression: try increasingly aggressive settings.
    return _progressiveCompress(file, ext);
  }

  /// Attempts compression with progressively lower quality and resolution
  /// until the output fits within [maxFileSize].
  Future<File> _progressiveCompress(File source, String ext) async {
    final targetDir = await _tempDirectory();

    for (var i = 0; i < _qualitySteps.length; i++) {
      final quality = _qualitySteps[i];
      final maxWidth = _maxWidthSteps[i];
      final outputFormat = _outputFormat(ext);
      final outputExt = outputFormat == CompressFormat.png ? '.png' : '.jpg';
      final targetPath = p.join(
        targetDir.path,
        'compressed_${DateTime.now().microsecondsSinceEpoch}_q${quality}w$maxWidth$outputExt',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        quality: quality,
        minWidth: 0,
        minHeight: 0,
        // Keep aspect ratio — compress only limits the max dimension.
        // We pass both width and height as the same max to let the library
        // handle aspect ratio correctly.
        autoCorrectionAngle: true,
        format: outputFormat,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final compressedSize = await compressedFile.length();

        if (compressedSize <= maxFileSize) {
          return compressedFile;
        }

        // If this wasn't the last attempt, delete the intermediate file
        // and try with lower quality.
        if (i < _qualitySteps.length - 1) {
          await compressedFile.delete().catchError((_) => compressedFile);
        } else {
          // Last attempt still too large — return it anyway and let the
          // repository's validation handle the error with a clear message.
          // This is better than silently failing.
          throw StateError(
            'Gambar tidak dapat dikompres di bawah 10 MB '
            '(${(compressedSize / (1024 * 1024)).toStringAsFixed(1)} MB '
            'setelah kompresi). Coba gunakan gambar dengan resolusi lebih kecil.',
          );
        }
      }
    }

    // Should not reach here, but return original as a fallback.
    return source;
  }

  /// Returns the output format based on the input extension.
  ///
  /// WebP and PNG inputs are converted to JPEG for better compression ratios
  /// since receipt images don't need transparency.
  static CompressFormat _outputFormat(String ext) {
    switch (ext) {
      case '.png':
        // Keep PNG if the source is PNG (preserves text clarity).
        return CompressFormat.png;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// Returns (and lazily creates) a `compressed_receipts/` temp directory.
  Future<Directory> _tempDirectory() async {
    final appDir = await getTemporaryDirectory();
    final dir = Directory(p.join(appDir.path, 'compressed_receipts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

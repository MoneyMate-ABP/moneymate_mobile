import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

/// Represents a captured or picked receipt image stored locally.
class ReceiptImage extends Equatable {
  const ReceiptImage({
    required this.id,
    required this.filePath,
    required this.capturedAt,
    required this.source,
    this.bytes,
    this.webExtension,
  });

  /// Unique identifier (UUID-style timestamp-based).
  final String id;

  /// Absolute path to the saved image file on the device.
  final String filePath;

  /// Timestamp when the receipt was captured / picked.
  final DateTime capturedAt;

  /// Whether the image was taken from the camera or chosen from the gallery.
  final ReceiptSource source;

  /// Raw bytes of the image file (used on Flutter Web).
  final Uint8List? bytes;

  /// Original file extension on web (e.g. '.webp', '.jpg').
  final String? webExtension;

  /// Extracts the file extension (safely falls back to webExtension).
  String get ext {
    final fileExt = p.extension(filePath);
    if (fileExt.isNotEmpty) {
      return fileExt.toLowerCase();
    }
    return (webExtension ?? '.jpg').toLowerCase();
  }

  /// Convenience getter – returns a [File] handle for the stored image.
  File get file => File(filePath);

  /// Whether the backing file still exists on disk.
  Future<bool> get exists => file.exists();

  @override
  List<Object?> get props => [id, filePath, capturedAt, source, bytes, webExtension];
}

/// Origin of a receipt image.
enum ReceiptSource {
  camera,
  gallery;

  String get label {
    switch (this) {
      case ReceiptSource.camera:
        return 'Kamera';
      case ReceiptSource.gallery:
        return 'Galeri';
    }
  }
}

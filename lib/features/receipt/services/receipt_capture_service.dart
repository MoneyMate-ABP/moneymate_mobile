import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/receipt_image.dart';

/// Service responsible for capturing receipt images from the device camera
/// or picking them from the photo gallery.
///
/// Captured images are persisted to the app's documents directory under
/// a `receipts/` subfolder so they survive app restarts.
class ReceiptCaptureService {
  ReceiptCaptureService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _imageQuality = 85;
  static const _maxWidth = 1080.0;
  static const _receiptDir = 'receipts';

  /// Opens the device camera and captures a photo.
  ///
  /// Returns a [ReceiptImage] with the saved file path, or `null` if the
  /// user cancelled the capture.
  Future<ReceiptImage?> captureFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: _imageQuality,
      maxWidth: _maxWidth,
    );
    if (xFile == null) return null;
    return _saveAndBuild(xFile, ReceiptSource.camera);
  }

  /// Opens the device gallery / photo library for the user to pick an image.
  ///
  /// Returns a [ReceiptImage] with the saved file path, or `null` if the
  /// user cancelled the selection.
  Future<ReceiptImage?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: _imageQuality,
      maxWidth: _maxWidth,
    );
    if (xFile == null) return null;
    return _saveAndBuild(xFile, ReceiptSource.gallery);
  }

  /// Opens the device gallery to pick multiple images.
  Future<List<ReceiptImage>> pickMultipleFromGallery() async {
    final xFiles = await _picker.pickMultiImage(
      imageQuality: _imageQuality,
      maxWidth: _maxWidth,
    );
    final results = <ReceiptImage>[];
    for (final xFile in xFiles) {
      final receipt = await _saveAndBuild(xFile, ReceiptSource.gallery);
      results.add(receipt);
    }
    return results;
  }

  /// Deletes the backing file for the given [receipt].
  ///
  /// Returns `true` if the file was successfully deleted, `false` if it
  /// did not exist.
  Future<bool> deleteReceipt(ReceiptImage receipt) async {
    if (kIsWeb) return true;
    final file = receipt.file;
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Copies the picked/captured [xFile] into the app's documents directory
  /// and returns a fully-populated [ReceiptImage].
  Future<ReceiptImage> _saveAndBuild(XFile xFile, ReceiptSource source) async {
    final id = _generateId();
    final bytes = await xFile.readAsBytes();

    if (kIsWeb) {
      return ReceiptImage(
        id: id,
        filePath: xFile.path,
        capturedAt: DateTime.now(),
        source: source,
        bytes: bytes,
        webExtension: p.extension(xFile.name).isNotEmpty ? p.extension(xFile.name) : '.jpg',
      );
    }

    final dir = await _receiptDirectory();
    final ext = p.extension(xFile.path).isNotEmpty ? p.extension(xFile.path) : '.jpg';
    final savedPath = p.join(dir.path, '$id$ext');

    final savedFile = File(savedPath);
    await savedFile.writeAsBytes(bytes);

    return ReceiptImage(
      id: id,
      filePath: savedPath,
      capturedAt: DateTime.now(),
      source: source,
      bytes: bytes,
    );
  }

  /// Returns (and lazily creates) the `receipts/` subdirectory inside the
  /// application documents directory.
  Future<Directory> _receiptDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _receiptDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Generates a simple unique ID based on the current microsecond timestamp.
  String _generateId() {
    return 'rcpt_${DateTime.now().microsecondsSinceEpoch}';
  }
}

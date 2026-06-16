import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../models/receipt_image.dart';
import '../models/receipt_scan_result.dart';
import '../repositories/receipt_scan_repository.dart';
import '../services/receipt_capture_service.dart';
import '../services/receipt_compressor.dart';

// ---------------------------------------------------------------------------
// Capture service provider
// ---------------------------------------------------------------------------

/// Provides a singleton [ReceiptCaptureService].
final receiptCaptureServiceProvider = Provider<ReceiptCaptureService>((ref) {
  return ReceiptCaptureService();
});

// ---------------------------------------------------------------------------
// Receipt list provider
// ---------------------------------------------------------------------------

/// Manages the in-memory list of captured receipt images.
///
/// Usage:
/// ```dart
/// // Read the list
/// final receipts = ref.watch(receiptListProvider);
///
/// // Add from camera
/// await ref.read(receiptListProvider.notifier).addFromCamera();
///
/// // Add from gallery
/// await ref.read(receiptListProvider.notifier).addFromGallery();
///
/// // Remove
/// await ref.read(receiptListProvider.notifier).remove('rcpt_123');
/// ```
final receiptListProvider =
    StateNotifierProvider<ReceiptListNotifier, List<ReceiptImage>>((ref) {
  final service = ref.watch(receiptCaptureServiceProvider);
  return ReceiptListNotifier(service);
});

/// [StateNotifier] that keeps a list of [ReceiptImage] instances and
/// delegates capture / deletion to [ReceiptCaptureService].
class ReceiptListNotifier extends StateNotifier<List<ReceiptImage>> {
  ReceiptListNotifier(this._service) : super(const []);

  final ReceiptCaptureService _service;

  /// Opens the camera, captures a receipt, and adds it to the list.
  ///
  /// Returns the new [ReceiptImage] or `null` if the user cancelled.
  Future<ReceiptImage?> addFromCamera() async {
    final receipt = await _service.captureFromCamera();
    if (receipt != null) {
      state = [...state, receipt];
    }
    return receipt;
  }

  /// Opens the gallery, picks a receipt image, and adds it to the list.
  ///
  /// Returns the new [ReceiptImage] or `null` if the user cancelled.
  Future<ReceiptImage?> addFromGallery() async {
    final receipt = await _service.pickFromGallery();
    if (receipt != null) {
      state = [...state, receipt];
    }
    return receipt;
  }

  /// Removes the receipt with [id] from the list and deletes its file.
  Future<void> remove(String id) async {
    final target = state.where((r) => r.id == id).firstOrNull;
    if (target != null) {
      await _service.deleteReceipt(target);
      state = state.where((r) => r.id != id).toList();
    }
  }
}

// ---------------------------------------------------------------------------
// Receipt scan repository provider
// ---------------------------------------------------------------------------

/// Provides a singleton [ReceiptScanRepository] backed by the shared
/// [ApiClient].
final receiptScanRepositoryProvider = Provider<ReceiptScanRepository>((ref) {
  return ReceiptScanRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Receipt compressor provider
// ---------------------------------------------------------------------------

/// Provides a singleton [ReceiptCompressor].
final receiptCompressorProvider = Provider<ReceiptCompressor>((ref) {
  return const ReceiptCompressor();
});

// ---------------------------------------------------------------------------
// Receipt scan state
// ---------------------------------------------------------------------------

/// Represents the current state of a receipt scan upload.
///
/// Transitions: `idle` → `compressing` → `uploading` → `success` | `error` → `idle`
sealed class ReceiptScanState {
  const ReceiptScanState();
}

/// No scan in progress.
class ReceiptScanIdle extends ReceiptScanState {
  const ReceiptScanIdle();
}

/// Image is being compressed before upload.
class ReceiptScanCompressing extends ReceiptScanState {
  const ReceiptScanCompressing();
}

/// Upload is in progress. [progress] is 0.0–1.0.
class ReceiptScanUploading extends ReceiptScanState {
  const ReceiptScanUploading({this.progress = 0.0});
  final double progress;
}

/// Scan completed successfully.
class ReceiptScanSuccess extends ReceiptScanState {
  const ReceiptScanSuccess(this.result);
  final ReceiptScanResult result;
}

/// Scan failed.
class ReceiptScanError extends ReceiptScanState {
  const ReceiptScanError(this.message);
  final String message;
}

/// Manages the receipt scan lifecycle: upload → AI parse → result.
///
/// Usage:
/// ```dart
/// // Start a scan
/// await ref.read(receiptScanProvider.notifier).scan(receiptImage);
///
/// // Watch scan state
/// final scanState = ref.watch(receiptScanProvider);
/// switch (scanState) {
///   case ReceiptScanIdle():     // show default UI
///   case ReceiptScanCompressing():                 // show compressing indicator
///   case ReceiptScanUploading(progress: final p): // show progress
///   case ReceiptScanSuccess(result: final r):     // navigate to form
///   case ReceiptScanError(message: final m):      // show error
/// }
///
/// // Reset back to idle
/// ref.read(receiptScanProvider.notifier).reset();
/// ```
final receiptScanProvider =
    StateNotifierProvider<ReceiptScanNotifier, ReceiptScanState>((ref) {
  final repository = ref.watch(receiptScanRepositoryProvider);
  final compressor = ref.watch(receiptCompressorProvider);
  return ReceiptScanNotifier(repository, compressor);
});

class ReceiptScanNotifier extends StateNotifier<ReceiptScanState> {
  ReceiptScanNotifier(this._repository, this._compressor)
      : super(const ReceiptScanIdle());

  final ReceiptScanRepository _repository;
  final ReceiptCompressor _compressor;

  /// Compresses (if needed) and uploads the receipt [image] file.
  ///
  /// State transitions: `compressing` → `uploading` → `success` | `error`.
  Future<void> scan(ReceiptImage image) async {
    try {
      // --- Phase 1: Compress image if over 10 MB ---
      state = const ReceiptScanCompressing();
      final fileToUpload = await _compressor.compressIfNeeded(image.file);

      // --- Phase 2: Upload ---
      state = const ReceiptScanUploading();
      final result = await _repository.scanReceipt(
        fileToUpload,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = ReceiptScanUploading(progress: sent / total);
          }
        },
      );
      state = ReceiptScanSuccess(result);
    } on ArgumentError catch (e) {
      state = ReceiptScanError(e.message?.toString() ?? 'Validasi gagal.');
    } on StateError catch (e) {
      state = ReceiptScanError(e.message);
    } on FormatException catch (e) {
      state = ReceiptScanError(e.message);
    } catch (e) {
      state = ReceiptScanError(e.toString());
    }
  }

  /// Resets the state back to [ReceiptScanIdle].
  void reset() {
    state = const ReceiptScanIdle();
  }
}


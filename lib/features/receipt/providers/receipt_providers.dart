import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/receipt_image.dart';
import '../services/receipt_capture_service.dart';

/// Provides a singleton [ReceiptCaptureService].
final receiptCaptureServiceProvider = Provider<ReceiptCaptureService>((ref) {
  return ReceiptCaptureService();
});

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

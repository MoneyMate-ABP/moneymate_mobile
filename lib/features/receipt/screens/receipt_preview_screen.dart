import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../../transactions/screens/transaction_form_screen.dart';
import '../models/receipt_image.dart';
import '../providers/receipt_providers.dart';

/// Full-screen preview of a single receipt image.
///
/// Supports pinch-to-zoom and panning via [InteractiveViewer].
/// Provides a delete action in the app bar and shows receipt metadata
/// (capture time and source) at the bottom.
class ReceiptPreviewScreen extends ConsumerWidget {
  const ReceiptPreviewScreen({required this.receipt, super.key});

  final ReceiptImage receipt;

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ReceiptScanState>(receiptScanProvider, (previous, next) {
      if (next is ReceiptScanSuccess) {
        // Reset scan state back to idle
        ref.read(receiptScanProvider.notifier).reset();

        // Navigate to TransactionFormScreen with prefilled draft
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TransactionFormScreen(scanResult: next.result),
          ),
        );
      } else if (next is ReceiptScanError) {
        // Show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: MoneyMateTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reset scan state back to idle
        ref.read(receiptScanProvider.notifier).reset();
      }
    });

    final scanState = ref.watch(receiptScanProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Preview Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus struk',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Zoomable image
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: kIsWeb
                  ? Image.network(
                      receipt.filePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 64, color: Colors.white38),
                          SizedBox(height: 12),
                          Text(
                            'Gambar tidak dapat dimuat.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    )
                  : Image.file(
                      File(receipt.filePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 64, color: Colors.white38),
                          SizedBox(height: 12),
                          Text(
                            'Gambar tidak dapat dimuat.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Bottom metadata & Scan Action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Source chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: MoneyMateTheme.accent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              receipt.source == ReceiptSource.camera
                                  ? Icons.camera_alt
                                  : Icons.photo_library,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              receipt.source.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Capture time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(receipt.capturedAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(receipt.capturedAt),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: scanState is! ReceiptScanIdle
                        ? null
                        : () => ref.read(receiptScanProvider.notifier).scan(receipt),
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Scan dengan AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MoneyMateTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (scanState is! ReceiptScanIdle)
            _ScanLoadingOverlay(state: scanState),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Struk?'),
        content:
            const Text('Struk yang sudah dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: MoneyMateTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(receiptListProvider.notifier).remove(receipt.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // go back to grid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hari ini';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ScanLoadingOverlay extends StatelessWidget {
  const _ScanLoadingOverlay({required this.state});
  final ReceiptScanState state;

  @override
  Widget build(BuildContext context) {
    String message = 'Memproses struk...';
    double? progress;

    if (state is ReceiptScanCompressing) {
      message = 'Mengompresi gambar struk...';
    } else if (state is ReceiptScanUploading) {
      final uploadState = state as ReceiptScanUploading;
      progress = uploadState.progress;
      final percent = (progress * 100).toStringAsFixed(0);
      message = 'Mengunggah struk ke server ($percent%)...';
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Card(
          color: MoneyMateTheme.surface,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: MoneyMateTheme.accent),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (progress != null && progress > 0) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(MoneyMateTheme.accent),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


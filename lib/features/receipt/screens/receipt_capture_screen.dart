import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/receipt_image.dart';
import '../providers/receipt_providers.dart';
import 'receipt_preview_screen.dart';

/// Main screen for capturing and viewing receipt images.
///
/// Provides two action buttons (camera & gallery) and displays captured
/// receipts in a grid layout. Tapping a receipt opens a full-screen preview;
/// long-pressing shows a delete confirmation dialog.
class ReceiptCaptureScreen extends ConsumerWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Struk'),
        centerTitle: false,
      ),
      body: receipts.isEmpty
          ? _EmptyState(onCamera: () => _capture(context, ref), onGallery: () => _pick(context, ref))
          : _ReceiptGrid(
              receipts: receipts,
              onTap: (receipt) => _openPreview(context, receipt),
              onDelete: (receipt) => _confirmDelete(context, ref, receipt),
            ),
      bottomNavigationBar: receipts.isNotEmpty
          ? _CaptureBottomBar(
              onCamera: () => _capture(context, ref),
              onGallery: () => _pick(context, ref),
            )
          : null,
    );
  }

  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    final receipt =
        await ref.read(receiptListProvider.notifier).addFromCamera();
    if (receipt == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengambilan foto dibatalkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final receipt =
        await ref.read(receiptListProvider.notifier).addFromGallery();
    if (receipt == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemilihan gambar dibatalkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPreview(BuildContext context, ReceiptImage receipt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptPreviewScreen(receipt: receipt),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ReceiptImage receipt,
  ) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Empty State
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MoneyMateTheme.accent.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: MoneyMateTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Struk',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ambil foto struk belanja Anda menggunakan kamera atau pilih dari galeri.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onPressed: onCamera,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onPressed: onGallery,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Receipt Grid
// -----------------------------------------------------------------------------

class _ReceiptGrid extends StatelessWidget {
  const _ReceiptGrid({
    required this.receipts,
    required this.onTap,
    required this.onDelete,
  });

  final List<ReceiptImage> receipts;
  final ValueChanged<ReceiptImage> onTap;
  final ValueChanged<ReceiptImage> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${receipts.length} struk diambil',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return _ReceiptThumbnail(
                  receipt: receipt,
                  onTap: () => onTap(receipt),
                  onLongPress: () => onDelete(receipt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Receipt Thumbnail Card
// -----------------------------------------------------------------------------

class _ReceiptThumbnail extends StatelessWidget {
  const _ReceiptThumbnail({
    required this.receipt,
    required this.onTap,
    required this.onLongPress,
  });

  final ReceiptImage receipt;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MoneyMateTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Receipt image
            Image.file(
              File(receipt.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: MoneyMateTheme.surface,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: MoneyMateTheme.textSecondary,
                  size: 40,
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          receipt.source == ReceiptSource.camera
                              ? Icons.camera_alt
                              : Icons.photo_library,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          receipt.source.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(receipt.capturedAt),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Source badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: MoneyMateTheme.accent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  receipt.source == ReceiptSource.camera
                      ? Icons.camera_alt
                      : Icons.photo_library,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// -----------------------------------------------------------------------------
// Bottom Capture Bar
// -----------------------------------------------------------------------------

class _CaptureBottomBar extends StatelessWidget {
  const _CaptureBottomBar({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: MoneyMateTheme.surface,
        border: const Border(
          top: BorderSide(color: MoneyMateTheme.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                onPressed: onCamera,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                onPressed: onGallery,
                isPrimary: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared Action Button
// -----------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: MoneyMateTheme.textPrimary,
        side: const BorderSide(color: MoneyMateTheme.accent),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

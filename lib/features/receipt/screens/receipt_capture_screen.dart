import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/receipt_image.dart';
import '../providers/receipt_providers.dart';
import 'receipt_preview_screen.dart';
import 'mutation_review_screen.dart';

class ReceiptCaptureScreen extends ConsumerStatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  ConsumerState<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends ConsumerState<ReceiptCaptureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Dokumen'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MoneyMateTheme.accent,
          labelColor: MoneyMateTheme.accent,
          unselectedLabelColor: MoneyMateTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Struk Belanja'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Mutasi Bank'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ReceiptTabContent(),
          _MutationTabContent(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab Content: Single Receipt
// -----------------------------------------------------------------------------

class _ReceiptTabContent extends ConsumerWidget {
  const _ReceiptTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptListProvider);

    return Scaffold(
      body: receipts.isEmpty
          ? _EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum Ada Struk',
              description: 'Ambil foto struk belanja Anda menggunakan kamera atau pilih dari galeri.',
              onCamera: () => _capture(context, ref),
              onGallery: () => _pick(context, ref),
            )
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
    final receipt = await ref.read(receiptListProvider.notifier).addFromCamera();
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
    final receipt = await ref.read(receiptListProvider.notifier).addFromGallery();
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
        content: const Text('Struk yang sudah dihapus tidak dapat dikembalikan.'),
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
// Tab Content: Bank Mutation Screenshots
// -----------------------------------------------------------------------------

class _MutationTabContent extends ConsumerWidget {
  const _MutationTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationScanState>(mutationScanProvider, (previous, next) {
      if (next is MutationScanSuccess) {
        ref.read(mutationScanProvider.notifier).reset();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MutationReviewScreen(results: next.results),
          ),
        );
      } else if (next is MutationScanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: MoneyMateTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(mutationScanProvider.notifier).reset();
      }
    });

    final mutations = ref.watch(mutationListProvider);
    final scanState = ref.watch(mutationScanProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          mutations.isEmpty
              ? _EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Belum Ada Mutasi',
                  description: 'Pilih satu atau beberapa screenshot mutasi rekening bank Anda dari galeri.',
                  onGallery: () => _pickMutations(context, ref),
                  isMutationMode: true,
                )
              : _ReceiptGrid(
                  receipts: mutations,
                  onTap: (img) => _openImagePreview(context, img),
                  onDelete: (img) => _confirmDeleteMutation(context, ref, img),
                ),
          if (scanState is! MutationScanIdle)
            _MutationScanOverlay(state: scanState),
        ],
      ),
      bottomNavigationBar: mutations.isNotEmpty
          ? _MutationBottomBar(
              onAdd: () => _pickMutations(context, ref),
              onProcess: () => ref.read(mutationScanProvider.notifier).scan(mutations),
              count: mutations.length,
              disabled: scanState is! MutationScanIdle,
            )
          : null,
    );
  }

  Future<void> _pickMutations(BuildContext context, WidgetRef ref) async {
    final list = await ref.read(mutationListProvider.notifier).addFromGallery();
    if (list.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemilihan screenshot dibatalkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openImagePreview(BuildContext context, ReceiptImage receipt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer(
              child: kIsWeb
                  ? Image.network(receipt.filePath)
                  : Image.file(File(receipt.filePath)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteMutation(
    BuildContext context,
    WidgetRef ref,
    ReceiptImage receipt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Gambar?'),
        content: const Text('Gambar mutasi yang sudah dihapus tidak dapat dikembalikan.'),
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
      await ref.read(mutationListProvider.notifier).remove(receipt.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar mutasi dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Mutation Bottom Bar
// -----------------------------------------------------------------------------

class _MutationBottomBar extends StatelessWidget {
  const _MutationBottomBar({
    required this.onAdd,
    required this.onProcess,
    required this.count,
    this.disabled = false,
  });

  final VoidCallback onAdd;
  final VoidCallback onProcess;
  final int count;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: MoneyMateTheme.surface,
        border: const Border(top: BorderSide(color: MoneyMateTheme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: disabled ? null : onAdd,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Tambah'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MoneyMateTheme.textPrimary,
                  side: const BorderSide(color: MoneyMateTheme.accent),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: disabled ? null : onProcess,
                icon: const Icon(Icons.psychology_rounded),
                label: Text('Proses Mutasi ($count)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MoneyMateTheme.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Mutation Scan Overlay
// -----------------------------------------------------------------------------

class _MutationScanOverlay extends StatelessWidget {
  const _MutationScanOverlay({required this.state});
  final MutationScanState state;

  @override
  Widget build(BuildContext context) {
    String message = 'Memproses screenshots mutasi...';
    if (state is MutationScanCompressing) {
      message = 'Mengompresi gambar mutasi...';
    } else if (state is MutationScanUploading) {
      message = 'Mengunggah dan mendeteksi transaksi oleh Gemini AI...';
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared / Helper Widgets
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.onCamera,
    required this.onGallery,
    this.isMutationMode = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onCamera;
  final VoidCallback onGallery;
  final bool isMutationMode;

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
              child: Icon(icon, size: 56, color: MoneyMateTheme.accent),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 32),
            if (isMutationMode)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Pilih dari Galeri'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCamera,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MoneyMateTheme.textPrimary,
                        side: const BorderSide(color: MoneyMateTheme.accent),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
            '${receipts.length} dokumen dipilih',
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
            kIsWeb
                ? Image.network(
                    receipt.filePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: MoneyMateTheme.surface,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: MoneyMateTheme.textSecondary,
                        size: 40,
                      ),
                    ),
                  )
                : Image.file(
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
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
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
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(receipt.capturedAt),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
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
        border: const Border(top: BorderSide(color: MoneyMateTheme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MoneyMateTheme.textPrimary,
                  side: const BorderSide(color: MoneyMateTheme.accent),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

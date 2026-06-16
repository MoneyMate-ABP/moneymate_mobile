import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../models/models.dart';
import '../providers.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final int transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  bool _deleting = false;

  Future<void> _delete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MoneyMateTheme.surface,
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Apakah kamu yakin ingin menghapus transaksi sebesar ${Formatter.formatRupiah(transaction.amount)}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MoneyMateTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(transaction.id);
      ref.invalidate(transactionsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus.'),
            backgroundColor: MoneyMateTheme.success,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus transaksi: $err'),
            backgroundColor: MoneyMateTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(transactionByIdProvider(widget.transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: detailState.maybeWhen(
          data: (transaction) => [
            IconButton(
              icon: const Icon(Icons.edit, color: MoneyMateTheme.accent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionFormScreen(transaction: transaction),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: MoneyMateTheme.danger),
              onPressed: _deleting ? null : () => _delete(transaction),
            ),
          ],
          orElse: () => [],
        ),
      ),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat transaksi: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(transactionByIdProvider(widget.transactionId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (transaction) {
          final isExpense = transaction.type == TransactionType.expense;
          final hasLocation = transaction.latitude != null && transaction.longitude != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Area
                Card(
                  color: isExpense 
                      ? MoneyMateTheme.danger.withValues(alpha: 0.1)
                      : MoneyMateTheme.success.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          isExpense ? '💸' : '💵',
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${isExpense ? "-" : "+"}${Formatter.formatRupiah(transaction.amount)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isExpense ? MoneyMateTheme.danger : MoneyMateTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isExpense ? 'Pengeluaran' : 'Pemasukan',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: MoneyMateTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Detail Items
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DetailItemRow(
                          label: 'Kategori',
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.categoryName ?? 'Kategori #${transaction.categoryId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        _DetailItemRow(
                          label: 'Tanggal',
                          value: Formatter.formatDate(transaction.date),
                        ),
                        const Divider(height: 24),
                        _DetailItemRow(
                          label: 'Tipe',
                          valueWidget: Text(
                            isExpense ? 'Pengeluaran' : 'Pemasukan',
                            style: TextStyle(
                              color: isExpense ? MoneyMateTheme.danger : MoneyMateTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (transaction.budgetPeriodName != null) ...[
                          const Divider(height: 24),
                          _DetailItemRow(
                            label: 'Periode Anggaran',
                            value: transaction.budgetPeriodName!,
                          ),
                        ],
                        const Divider(height: 24),
                        _DetailItemRow(
                          label: 'Catatan',
                          value: transaction.note?.isNotEmpty == true
                              ? transaction.note
                              : 'Tidak ada catatan',
                          valueStyle: transaction.note?.isNotEmpty == true
                              ? null
                              : const TextStyle(fontStyle: FontStyle.italic, color: MoneyMateTheme.textSecondary),
                        ),
                        const Divider(height: 24),
                        _DetailItemRow(
                          label: 'Lokasi',
                          valueWidget: hasLocation
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${transaction.latitude!.toStringAsFixed(5)}, ${transaction.longitude!.toStringAsFixed(5)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(Icons.map, size: 14),
                                      label: const Text('Buka di Peta'),
                                      onPressed: () {
                                        // Simple placeholder for opening maps
                                      },
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Tidak ada data lokasi',
                                  style: TextStyle(fontStyle: FontStyle.italic, color: MoneyMateTheme.textSecondary),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  const _DetailItemRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.valueStyle,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(color: MoneyMateTheme.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget ??
                Text(
                  value ?? '',
                  style: valueStyle ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.end,
                ),
          ),
        ),
      ],
    );
  }
}

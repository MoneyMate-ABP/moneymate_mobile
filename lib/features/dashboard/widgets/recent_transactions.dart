import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/providers.dart';
import '../../receipt/screens/receipt_capture_screen.dart';
import '../../transactions/models/models.dart';
import '../../transactions/providers.dart';
import '../../transactions/screens/transaction_form_screen.dart';
import '../../transactions/widgets/transaction_tile.dart';


class RecentTransactions extends ConsumerWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Transaksi Terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                txState.maybeWhen(
                  data: (res) {
                    if (res.data.isEmpty) return const SizedBox.shrink();
                    final count = res.data.length > 5 ? 5 : res.data.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count terakhir',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: MoneyMateTheme.textSecondary,
                            ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Switch bottom nav tab to 'Transaksi' (index 1)
                ref.read(navigationIndexProvider.notifier).state = 1;
              },
              child: const Text('List Transaksi'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        txState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Gagal memuat transaksi: $err',
              style: const TextStyle(color: MoneyMateTheme.danger),
            ),
          ),
          data: (res) {
            if (res.data.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi.',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mulai catat pemasukan dan pengeluaranmu!',
                      style: TextStyle(
                        color: MoneyMateTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),
                    _buildActionButtons(context),
                  ],
                ),
              );
            }

            // Sort newest first & take first 5
            final sortedList = List<Transaction>.from(res.data)
              ..sort((a, b) => b.date.compareTo(a.date));
            final recentList = sortedList.take(5).toList();

            return Column(
              children: [
                ...recentList.map((tx) => TransactionTile(transaction: tx)),
                const SizedBox(height: 8),
                _buildActionButtons(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _ActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceiptCaptureScreen(),
                ),
              );
            },
            isOutlined: true,
            icon: Icons.receipt_long_rounded,
            label: 'Scan Struk',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(),
                ),
              );
            },
            isOutlined: false,
            icon: Icons.add,
            label: 'Tambah Transaksi',
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.onPressed,
    required this.isOutlined,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData icon;
  final String label;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 48,
          decoration: widget.isOutlined
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: MoneyMateTheme.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                )
              : BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF8A84FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isOutlined ? MoneyMateTheme.accent : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isOutlined ? MoneyMateTheme.accent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

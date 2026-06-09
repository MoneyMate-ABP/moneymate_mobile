import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/dashboard_summary.dart';
import '../providers.dart';

/// FLT-302: Widget ringkasan saldo dan transaksi untuk Dashboard.
///
/// Menampilkan lima kartu:
/// 1. Total Saldo
/// 2. Total Pemasukan
/// 3. Total Pengeluaran
/// 4. Pengeluaran Hari Ini
/// 5. Sisa Saldo Hari Ini
///
/// Mendukung tiga state:
/// - **Loading**: Skeleton shimmer indicator.
/// - **Error**: Pesan error dengan tombol retry.
/// - **Data**: Kartu ringkasan dengan nilai nyata.
///
/// Usage:
/// ```dart
/// const DashboardSummaryCard()
/// ```
class DashboardSummaryCard extends ConsumerWidget {
  const DashboardSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardSummaryProvider);

    return summaryState.when(
      loading: () => const _SummaryLoadingState(),
      error: (error, _) => _SummaryErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (summary) => _SummaryDataState(summary: summary),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading State
// ---------------------------------------------------------------------------

class _SummaryLoadingState extends StatelessWidget {
  const _SummaryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Ringkasan Keuangan'),
        const SizedBox(height: 12),
        _BalanceCardSkeleton(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MiniCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _MiniCardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MiniCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _MiniCardSkeleton()),
          ],
        ),
      ],
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Skeleton(
      width: double.infinity,
      height: 100,
      borderRadius: 16,
    );
  }
}

class _MiniCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Skeleton(
      width: double.infinity,
      height: 80,
      borderRadius: 12,
    );
  }
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _opacity.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _SummaryErrorState extends StatelessWidget {
  const _SummaryErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: MoneyMateTheme.danger, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Gagal memuat ringkasan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MoneyMateTheme.danger,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: MoneyMateTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data State
// ---------------------------------------------------------------------------

class _SummaryDataState extends StatelessWidget {
  const _SummaryDataState({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Ringkasan Keuangan'),
        const SizedBox(height: 12),
        // ---- Total Saldo -------------------------------------------------------
        _BalanceCard(balance: summary.totalBalance),
        const SizedBox(height: 12),
        // ---- Pemasukan & Pengeluaran -------------------------------------------
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Total Pemasukan',
                amount: summary.totalIncome,
                icon: Icons.arrow_downward_rounded,
                color: MoneyMateTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Total Pengeluaran',
                amount: summary.totalExpense,
                icon: Icons.arrow_upward_rounded,
                color: MoneyMateTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ---- Hari Ini ----------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Pengeluaran\nHari Ini',
                amount: summary.todayExpense,
                icon: Icons.today_rounded,
                color: MoneyMateTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Sisa Saldo\nHari Ini',
                amount: summary.todayRemaining,
                icon: Icons.account_balance_wallet_rounded,
                color: summary.todayRemaining >= 0
                    ? MoneyMateTheme.accent
                    : MoneyMateTheme.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
    );
  }
}

/// Kartu utama Total Saldo dengan gradient.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3D35BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MoneyMateTheme.accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Total Saldo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(balance),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// Kartu statistik kecil (pemasukan, pengeluaran, dsb.).
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MoneyMateTheme.textSecondary,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatRupiah(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 13,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Format angka ke format Rupiah, e.g. `Rp 5.000.000`.
String _formatRupiah(double amount) {
  final isNegative = amount < 0;
  final abs = amount.abs();
  final intPart = abs.toInt();
  final str = intPart.toString();

  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }

  return '${isNegative ? '-' : ''}Rp ${buffer.toString()}';
}

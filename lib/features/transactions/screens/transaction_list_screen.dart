import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/models.dart';
import '../providers.dart';
import '../widgets/income_expense_summary.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_list_content.dart';
import '../../receipt/screens/receipt_capture_screen.dart';

/// The month-filter state lives in a [StateProvider] so it is shared between
/// the summary card and the list.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Fetches transactions filtered to the currently selected month.
///
/// The date filter is sent as `YYYY-MM` and the API is expected to return all
/// transactions for that month.  If the API does not support a month prefix
/// filter, this provider fetches all transactions and filters client-side.
final transactionsByMonthProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  // Fetch all transactions; we filter on the client because the API only
  // supports an exact date filter, not a month prefix filter.
  final response = await repo.listTransactions();

  // Keep only transactions whose date starts with "YYYY-MM".
  final prefix =
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  return response.data.where((t) => t.date.startsWith(prefix)).toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // newest first
});

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionsByMonthProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReceiptCaptureScreen(),
            ),
          );
        },
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('Scan Struk'),
        backgroundColor: MoneyMateTheme.accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Transaksi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),

          // ── Month Selector ────────────────────────────────────────────────
          const MonthSelector(),
          const SizedBox(height: 16),

          // ── Income / Expense Summary ──────────────────────────────────────
          txState.when(
            loading: () => const _SummarySkeleton(),
            error: (err, st) => const SizedBox.shrink(),
            data: (transactions) =>
                IncomeExpenseSummary(transactions: transactions),
          ),
          const SizedBox(height: 8),

          // ── Transaction List ──────────────────────────────────────────────
          Expanded(
            child: txState.when(
              loading: () => const _ListSkeleton(),
              error: (error, stackTrace) => _ErrorState(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(transactionsByMonthProvider),
              ),
              data: (transactions) => transactions.isEmpty
                  ? const _EmptyState()
                  : TransactionListContent(transactions: transactions),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading Skeletons ──────────────────────────────────────────────────────────

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _Shimmer(height: 80, borderRadius: 14)),
          const SizedBox(width: 12),
          Expanded(child: _Shimmer(height: 80, borderRadius: 14)),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, _) => Row(
        children: [
          _Shimmer(height: 44, width: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(height: 14, borderRadius: 7, widthFactor: 0.6),
                const SizedBox(height: 6),
                _Shimmer(height: 11, borderRadius: 6, widthFactor: 0.4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Shimmer(height: 14, width: 64, borderRadius: 7),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.height,
    this.width,
    required this.borderRadius,
    this.widthFactor,
  });

  final double height;
  final double? width;
  final double borderRadius;
  final double? widthFactor;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.04, end: 0.12).animate(
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
      animation: _animation,
      builder: (context, _) {
        return FractionallySizedBox(
          widthFactor: widget.widthFactor,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _animation.value),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MoneyMateTheme.accent.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: MoneyMateTheme.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Transaksi',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada transaksi pada bulan ini.\nMulai catat dengan tombol di bawah.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MoneyMateTheme.danger.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: MoneyMateTheme.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal Memuat Data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message.length > 120 ? '${message.substring(0, 120)}…' : message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/models.dart';
import '../providers.dart';
import '../widgets/income_expense_summary.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_filter_sheet.dart';
import '../widgets/transaction_list_content.dart';
import '../../receipt/screens/receipt_capture_screen.dart';

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------

/// The month the user is currently browsing.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Active filters applied on top of the month selection.
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);

// ---------------------------------------------------------------------------
// Derived data providers
// ---------------------------------------------------------------------------

/// Fetches all transactions for the selected month, then applies the active
/// [TransactionFilter] on the client side.
final filteredTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final filter = ref.watch(transactionFilterProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  // Fetch all transactions and filter by month prefix client-side.
  final response = await repo.listTransactions();

  final prefix =
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  var list = response.data.where((t) => t.date.startsWith(prefix)).toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // newest first

  // ── Apply additional filters ────────────────────────────────────────────

  // Type filter
  if (filter.type != null) {
    list = list.where((t) => t.type == filter.type).toList();
  }

  // Date range filter (overrides the month prefix on both ends if set)
  if (filter.startDate != null) {
    final start = _dateStr(filter.startDate!);
    list = list.where((t) => t.date.compareTo(start) >= 0).toList();
  }
  if (filter.endDate != null) {
    final end = _dateStr(filter.endDate!);
    list = list.where((t) => t.date.compareTo(end) <= 0).toList();
  }

  // Category / search filter
  final q = (filter.searchQuery ?? '').trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((t) {
      final cat = (t.categoryName ?? '').toLowerCase();
      final note = (t.note ?? '').toLowerCase();
      final amount = t.amount.toStringAsFixed(0);
      return cat.contains(q) || note.contains(q) || amount.contains(q);
    }).toList();
  }

  return list;
});

/// Convenience alias kept for backward-compat with older widget references.
@Deprecated('Use filteredTransactionsProvider')
final transactionsByMonthProvider = filteredTransactionsProvider;

// ── Helper ──────────────────────────────────────────────────────────────────

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TransactionFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final activeCount = _countActiveFilters(filter);

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
          // ── Header + Filter button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 20, 0),
            child: Row(
              children: [
                Text(
                  'Transaksi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                _FilterButton(
                  activeCount: activeCount,
                  onTap: () => _openFilterSheet(context),
                  onClear: activeCount > 0
                      ? () => ref
                          .read(transactionFilterProvider.notifier)
                          .state = const TransactionFilter()
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Month Selector ────────────────────────────────────────────────
          const MonthSelector(),
          const SizedBox(height: 16),

          // ── Active filter chips row ───────────────────────────────────────
          if (filter.isActive) ...[
            _ActiveFilterChips(filter: filter, ref: ref),
            const SizedBox(height: 8),
          ],

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
                onRetry: () => ref.invalidate(filteredTransactionsProvider),
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

  int _countActiveFilters(TransactionFilter f) {
    int c = 0;
    if (f.type != null) c++;
    if (f.startDate != null || f.endDate != null) c++;
    if (f.searchQuery != null && f.searchQuery!.isNotEmpty) c++;
    return c;
  }
}

// ── Filter Button ─────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
    this.onClear,
  });

  final int activeCount;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasActive
              ? MoneyMateTheme.accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasActive
                ? MoneyMateTheme.accent.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: hasActive
                  ? MoneyMateTheme.accent
                  : MoneyMateTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasActive
                    ? MoneyMateTheme.accent
                    : MoneyMateTheme.textSecondary,
              ),
            ),
            if (hasActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: MoneyMateTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Active filter chips ────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filter, required this.ref});

  final TransactionFilter filter;
  final WidgetRef ref;

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _update(TransactionFilter updated) {
    ref.read(transactionFilterProvider.notifier).state = updated;
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.type != null) {
      chips.add(_Chip(
        label: filter.type == TransactionType.income
            ? 'Pemasukan'
            : 'Pengeluaran',
        icon: filter.type == TransactionType.income
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded,
        color: filter.type == TransactionType.income
            ? MoneyMateTheme.success
            : MoneyMateTheme.danger,
        onRemove: () => _update(filter.copyWith(type: null)),
      ));
    }

    if (filter.startDate != null || filter.endDate != null) {
      final from = filter.startDate != null
          ? _dateLabel(filter.startDate!)
          : '…';
      final to =
          filter.endDate != null ? _dateLabel(filter.endDate!) : '…';
      chips.add(_Chip(
        label: '$from → $to',
        icon: Icons.date_range_rounded,
        color: MoneyMateTheme.accent,
        onRemove: () =>
            _update(filter.copyWith(startDate: null, endDate: null)),
      ));
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      chips.add(_Chip(
        label: '"${filter.searchQuery}"',
        icon: Icons.search_rounded,
        color: MoneyMateTheme.accent,
        onRemove: () => _update(filter.copyWith(searchQuery: null)),
      ));
    }

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => chips[i],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
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
              'Tidak Ada Hasil',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada transaksi yang cocok dengan filter.\nCoba ubah atau hapus filter.',
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

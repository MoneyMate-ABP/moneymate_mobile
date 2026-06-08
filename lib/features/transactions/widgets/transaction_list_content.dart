import 'package:flutter/material.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/models.dart';

/// Renders a list of [transactions] grouped by date with sticky date headers.
///
/// Each item shows:
/// • Category icon circle (income = green, expense = red)
/// • Category name & optional note
/// • Formatted amount with colour coding
class TransactionListContent extends StatelessWidget {
  const TransactionListContent({required this.transactions, super.key});

  final List<Transaction> transactions;

  static final _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Groups [transactions] by their [Transaction.date] string.
  /// Assumes the list is already sorted newest first.
  static Map<String, List<Transaction>> _groupByDate(
    List<Transaction> transactions,
  ) {
    final map = <String, List<Transaction>>{};
    for (final t in transactions) {
      (map[t.date] ??= []).add(t);
    }
    return map;
  }

  static String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];
    final monthName =
        month >= 1 && month <= 12 ? _monthNames[month] : '';
    return '$day $monthName $year';
  }

  static String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write('.');
      buffer.write(parts[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(transactions);
    // Keep date order newest first.
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Flatten into a mixed list of headers and items for the ListView.
    final items = <_ListEntry>[];
    for (final date in dates) {
      items.add(_HeaderEntry(date));
      for (final t in grouped[date]!) {
        items.add(_TransactionEntry(t));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 100, // room for FAB
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        if (entry is _HeaderEntry) {
          return _DateHeader(date: entry.date);
        }
        final te = entry as _TransactionEntry;
        return _TransactionTile(transaction: te.transaction);
      },
    );
  }
}

// ── Internal helpers ───────────────────────────────────────────────────────────

abstract class _ListEntry {}

class _HeaderEntry extends _ListEntry {
  _HeaderEntry(this.date);
  final String date;
}

class _TransactionEntry extends _ListEntry {
  _TransactionEntry(this.transaction);
  final Transaction transaction;
}

// ── Date header ────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        TransactionListContent._formatDate(date),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MoneyMateTheme.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Transaction tile ───────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color =
        isIncome ? MoneyMateTheme.success : MoneyMateTheme.danger;
    final sign = isIncome ? '+' : '-';
    final categoryLabel =
        transaction.categoryName ?? 'Kategori #${transaction.categoryId}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          title: Text(
            categoryLabel,
            style: const TextStyle(
              color: MoneyMateTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: transaction.note != null && transaction.note!.isNotEmpty
              ? Text(
                  transaction.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoneyMateTheme.textSecondary,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Text(
            '$sign${TransactionListContent._formatCurrency(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

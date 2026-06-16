import 'package:flutter/material.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/models.dart';

/// Compact two-card row showing total income vs total expense for the month.
///
/// Each card shows:
///  • Coloured icon
///  • Label ("Pemasukan" / "Pengeluaran")
///  • Formatted amount in IDR
///  • Percentage of combined total as a thin progress bar
class IncomeExpenseSummary extends StatelessWidget {
  const IncomeExpenseSummary({required this.transactions, super.key});

  final List<Transaction> transactions;

  static String _formatCurrency(double amount) {
    // Simple IDR formatter — no intl dependency needed.
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
    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    final combined = totalIncome + totalExpense;
    final incomeFraction = combined == 0 ? 0.0 : totalIncome / combined;
    final expenseFraction = combined == 0 ? 0.0 : totalExpense / combined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.arrow_downward_rounded,
              label: 'Pemasukan',
              amount: _formatCurrency(totalIncome),
              fraction: incomeFraction,
              color: MoneyMateTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              icon: Icons.arrow_upward_rounded,
              label: 'Pengeluaran',
              amount: _formatCurrency(totalExpense),
              fraction: expenseFraction,
              color: MoneyMateTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.fraction,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String amount;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label row
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MoneyMateTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Amount
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(fraction * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              color: MoneyMateTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../models/dashboard_budget_status.dart';

class BudgetStatusBar extends StatelessWidget {
  const BudgetStatusBar({
    required this.status,
    super.key,
  });

  final DashboardBudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final daily = status.dailyStatus;
    if (daily == null) return const SizedBox.shrink();

    final isCarryOverSystem = status.budgetSystem == 'carry_over';
    final shownBudget = isCarryOverSystem ? daily.effectiveBudget : daily.base;
    final remaining = daily.remaining;
    final isSurplus = remaining >= 0;
    
    final percentage = shownBudget > 0
        ? (daily.totalSpent / shownBudget).clamp(0.0, 1.0)
        : (daily.totalSpent > 0 ? 1.0 : 0.0);

    final statusColor = isSurplus ? MoneyMateTheme.success : MoneyMateTheme.danger;
    final statusLabel = isSurplus ? 'Lebih' : 'Kurang';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name & Badges
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          status.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (status.categoryName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MoneyMateTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.categoryName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: MoneyMateTheme.accent,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                      if (daily.isWeekend) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MoneyMateTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Weekend',
                            style: TextStyle(
                              color: MoneyMateTheme.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge Status (Lebih / Kurang)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar track
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(3),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: percentage),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: val,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSurplus
                              ? [MoneyMateTheme.success, const Color(0xFF27AE60)]
                              : [MoneyMateTheme.danger, const Color(0xFFFF6B81)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: (isSurplus ? MoneyMateTheme.success : MoneyMateTheme.danger)
                                .withValues(alpha: 0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Detail values row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DetailCol(
                  label: isCarryOverSystem ? 'Budget Hari Ini' : 'Budget Harian',
                  value: Formatter.formatRupiah(shownBudget),
                ),
                _DetailCol(
                  label: 'Terpakai',
                  value: Formatter.formatRupiah(daily.totalSpent),
                  valueColor: const Color(0xFFFF6B7A),
                ),
                _DetailCol(
                  label: 'Sisa',
                  value: Formatter.formatRupiah(remaining),
                  valueColor: statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCol extends StatelessWidget {
  const _DetailCol({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MoneyMateTheme.textSecondary,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

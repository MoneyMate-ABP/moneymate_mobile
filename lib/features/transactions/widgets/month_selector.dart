import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../screens/transaction_list_screen.dart';

/// Horizontally scrollable row of month chips (current month + 11 months back).
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  static final _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMonthProvider);
    final now = DateTime.now();

    // Build a list of 13 months: from 12 months ago to the current month.
    final months = List.generate(13, (i) {
      final offset = 12 - i;
      return DateTime(now.year, now.month - offset);
    });

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = months[index];
          final isSelected =
              m.year == selected.year && m.month == selected.month;
          final label =
              '${_monthNames[m.month - 1]} ${m.year}';

          return GestureDetector(
            onTap: () {
              ref
                  .read(selectedMonthProvider.notifier)
                  .state = DateTime(m.year, m.month);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? MoneyMateTheme.accent
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : MoneyMateTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

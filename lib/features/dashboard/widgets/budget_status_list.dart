import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../budget/screens/invest_savings_screen.dart';
import '../providers.dart';
import 'budget_status_bar.dart';

class BudgetStatusList extends ConsumerWidget {
  const BudgetStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return dashboardState.when(
      loading: () => const SizedBox.shrink(), // Or budget card skeleton if needed
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final budgets = data.budgets;
        final statuses = budgets.status;
        if (statuses.isEmpty) return const SizedBox.shrink();

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
                      'Anggaran Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${budgets.activeCount} aktif',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: MoneyMateTheme.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvestSavingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Tabungan'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...statuses.map((status) => BudgetStatusBar(status: status)),
          ],
        );
      },
    );
  }
}

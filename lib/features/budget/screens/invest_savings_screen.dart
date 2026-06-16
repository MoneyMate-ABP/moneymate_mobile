import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../providers.dart';
import 'budget_form_screen.dart';
import 'daily_status_screen.dart';

class InvestSavingsScreen extends ConsumerWidget {
  const InvestSavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investState = ref.watch(investSavingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabungan'),
      ),
      body: investState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat tabungan: $err')),
        data: (summary) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💰 Total Tabungan', style: TextStyle(fontSize: 12, color: MoneyMateTheme.textSecondary)),
                              const SizedBox(height: 8),
                              Text(
                                Formatter.formatRupiah(summary.totalInvested),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: MoneyMateTheme.success,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📦 Periode', style: TextStyle(fontSize: 12, color: MoneyMateTheme.textSecondary)),
                              const SizedBox(height: 8),
                              Text(
                                '${summary.periodCount}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Periods List
              Expanded(
                child: summary.periods.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏦', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada tabungan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Buat anggaran dengan sistem Tabungan untuk mulai menabung otomatis.',
                                style: TextStyle(color: MoneyMateTheme.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BudgetFormScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Buat Anggaran Tabungan'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: summary.periods.length,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemBuilder: (context, index) {
                          final period = summary.periods[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              period.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (period.categoryName != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                period.categoryName!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: MoneyMateTheme.accent,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: MoneyMateTheme.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Tabungan',
                                          style: TextStyle(
                                            color: MoneyMateTheme.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${Formatter.formatDate(period.startDate)} – ${Formatter.formatDate(period.endDate)}',
                                    style: const TextStyle(fontSize: 11, color: MoneyMateTheme.textSecondary),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Tabungan Terkumpul',
                                            style: TextStyle(fontSize: 11, color: MoneyMateTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            Formatter.formatRupiah(period.investedTotal),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: MoneyMateTheme.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Hari Terlacak',
                                            style: TextStyle(fontSize: 11, color: MoneyMateTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${period.trackedDays} hari',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DailyStatusScreen(budgetPeriodId: period.budgetPeriodId),
                                        ),
                                      );
                                    },
                                    child: const Text('Lihat Status Harian'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },

                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../providers.dart';

class DailyStatusScreen extends ConsumerWidget {
  const DailyStatusScreen({required this.budgetPeriodId, super.key});

  final int budgetPeriodId;

  String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      return days[date.weekday % 7];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsState = ref.watch(budgetPeriodsProvider);
    final dailyState = ref.watch(budgetDailyStatusesProvider(budgetPeriodId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Harian'),
      ),
      body: periodsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat budget: $err')),
        data: (periodsRes) {
          final period = periodsRes.data.firstWhere(
            (p) => p.id == budgetPeriodId,
            orElse: () => throw Exception('Budget tidak ditemukan'),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Summary Card
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Formatter.formatDate(period.startDate)} – ${Formatter.formatDate(period.endDate)}',
                          style: const TextStyle(fontSize: 11, color: MoneyMateTheme.textSecondary),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SummaryCol(
                              label: 'Total Budget',
                              value: Formatter.formatRupiah(period.totalBudget),
                            ),
                            _SummaryCol(
                              label: 'Budget Harian',
                              value: Formatter.formatRupiah(period.dailyBudgetBase),
                            ),
                            _SummaryCol(
                              label: 'Hari Kerja',
                              value: '${period.workingDaysCount} hari',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LegendItem(color: MoneyMateTheme.success, label: 'Lebih'),
                      const SizedBox(width: 12),
                      _LegendItem(color: MoneyMateTheme.danger, label: 'Kurang'),
                      const SizedBox(width: 12),
                      _LegendItem(color: Colors.white24, label: 'Weekend'),
                      const SizedBox(width: 12),
                      _LegendItem(color: MoneyMateTheme.accent, label: 'Hari Ini'),
                    ],
                  ),
                ),
              ),

              // Day-by-Day List
              Expanded(
                child: dailyState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Gagal memuat status harian: $err')),
                  data: (statuses) {
                    if (statuses.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada data harian.',
                          style: TextStyle(color: MoneyMateTheme.textSecondary),
                        ),
                      );
                    }

                    // Sort newest first
                    final sorted = List.from(statuses)
                      ..sort((a, b) => b.date.compareTo(a.date));

                    return ListView.builder(
                      itemCount: sorted.length,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemBuilder: (context, index) {
                        final status = sorted[index];
                        final isWeekend = status.isWeekend;
                        final isSurplus = status.remaining >= 0;
                        
                        final today = DateTime.now().toIso8601String().split('T')[0];
                        final isTodayDay = status.date == today;

                        Color statusColor = isSurplus ? MoneyMateTheme.success : MoneyMateTheme.danger;
                        if (isWeekend) statusColor = Colors.white24;
                        if (isTodayDay) statusColor = MoneyMateTheme.accent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTodayDay 
                                  ? MoneyMateTheme.accent.withValues(alpha: 0.6) 
                                  : statusColor.withValues(alpha: 0.2),
                              width: isTodayDay ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Formatter.formatDate(status.date),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _getDayName(status.date),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: MoneyMateTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        Formatter.formatRupiah(status.remaining),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _StatItem(
                                      label: 'Budget Harian',
                                      value: Formatter.formatRupiah(status.base),
                                    ),
                                    _StatItem(
                                      label: 'Sisa Kemarin',
                                      value: (status.carryOver > 0 ? '+' : '') + Formatter.formatRupiah(status.carryOver),
                                      valueColor: status.carryOver > 0 
                                          ? MoneyMateTheme.success 
                                          : status.carryOver < 0 ? MoneyMateTheme.danger : null,
                                    ),
                                    _StatItem(
                                      label: 'Terpakai',
                                      value: Formatter.formatRupiah(status.totalSpent),
                                      valueColor: status.totalSpent > 0 ? const Color(0xFFFF6B7A) : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

class _SummaryCol extends StatelessWidget {
  const _SummaryCol({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: MoneyMateTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: MoneyMateTheme.textSecondary),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
          style: const TextStyle(fontSize: 10, color: MoneyMateTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

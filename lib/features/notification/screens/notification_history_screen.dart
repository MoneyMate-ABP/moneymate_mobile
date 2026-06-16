import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../models/notification_history.dart';
import '../providers.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  String _formatRelativeDay(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final today = DateTime.now();
      final difference = DateTime(today.year, today.month, today.day)
          .difference(DateTime(parsed.year, parsed.month, parsed.day))
          .inDays;

      if (difference == 0) return 'hari ini';
      if (difference == 1) return 'kemarin';
      return '$difference hari lalu';
    } catch (_) {
      return '';
    }
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref, NotificationHistory item) async {
    if (item.isRead) return;
    try {
      await ref.read(notificationRepositoryProvider).markRead(item.id);
      ref.invalidate(notificationHistoryProvider);
    } catch (_) {}
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai telah dibaca.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(notificationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          historyState.when(
            data: (res) => res.unreadCount > 0
                ? TextButton(
                    onPressed: () => _markAllRead(context, ref),
                    child: const Text('Tandai Semua Dibaca'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(notificationHistoryProvider),
        child: historyState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat notifikasi: $err')),
          data: (res) {
            final list = res.data;
            if (list.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 64, color: MoneyMateTheme.textSecondary),
                    SizedBox(height: 16),
                    Text('Belum ada notifikasi', style: TextStyle(color: MoneyMateTheme.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                final carryOverVal = item.carryOver;
                final isPositive = carryOverVal > 0;
                final isNegative = carryOverVal < 0;

                final carryColor = isPositive
                    ? MoneyMateTheme.success
                    : isNegative
                        ? MoneyMateTheme.danger
                        : MoneyMateTheme.textSecondary;

                final carryPrefix = isPositive ? '+' : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: item.isRead 
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.isRead 
                          ? Colors.white.withValues(alpha: 0.05)
                          : MoneyMateTheme.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _markRead(context, ref, item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: item.isRead ? MoneyMateTheme.textPrimary : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRelativeDay(item.sentAt),
                                style: const TextStyle(
                                  color: MoneyMateTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.body,
                            style: TextStyle(
                              color: item.isRead ? MoneyMateTheme.textSecondary : MoneyMateTheme.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const Divider(height: 24, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Anggaran harian: ${Formatter.formatRupiah(item.effectiveBudget)}',
                                style: const TextStyle(
                                  color: MoneyMateTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Sisa kemarin: $carryPrefix${Formatter.formatRupiah(carryOverVal)}',
                                style: TextStyle(
                                  color: carryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

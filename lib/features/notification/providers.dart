import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'models/notification_history.dart';
import 'repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

final notificationHistoryProvider =
    FutureProvider<NotificationHistoryResponse>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getHistory();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final history = ref.watch(notificationHistoryProvider).value;
  return history?.unreadCount ?? 0;
});

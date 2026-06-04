import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'models/dashboard_data.dart';
import 'repositories/dashboard_repository.dart';

/// Provides a singleton [DashboardRepository] backed by the shared [ApiClient].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

/// Fetches and exposes the dashboard data as an [AsyncValue<DashboardData>].
///
/// Usage in a widget:
/// ```dart
/// final state = ref.watch(dashboardProvider);
/// state.when(
///   loading: () => const CircularProgressIndicator(),
///   error:   (err, _) => Text('Error: $err'),
///   data:    (data) => Text('Balance: ${data.totals.balance}'),
/// );
/// ```
///
/// To re-fetch (e.g. pull-to-refresh):
/// ```dart
/// ref.invalidate(dashboardProvider);
/// ```
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.fetchDashboard();
});

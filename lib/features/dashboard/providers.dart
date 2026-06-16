import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'models/dashboard_data.dart';
import 'models/dashboard_summary.dart';
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

// ---------------------------------------------------------------------------
// FLT-302: Dashboard Summary Provider
// ---------------------------------------------------------------------------

/// Derives [DashboardSummary] from [dashboardProvider].
///
/// Menampilkan ringkasan:
/// - Total Saldo
/// - Total Pemasukan
/// - Total Pengeluaran
/// - Pengeluaran Hari Ini
/// - Sisa Saldo Hari Ini
///
/// Usage:
/// ```dart
/// final summaryState = ref.watch(dashboardSummaryProvider);
/// summaryState.when(
///   loading: () => const CircularProgressIndicator(),
///   error:   (err, _) => Text('Error: $err'),
///   data:    (s) => Text('Saldo: ${s.totalBalance}'),
/// );
/// ```
///
/// To re-fetch:
/// ```dart
/// ref.invalidate(dashboardProvider); // invalidate parent to refresh summary
/// ```
final dashboardSummaryProvider =
    FutureProvider<DashboardSummary>((ref) async {
  final data = await ref.watch(dashboardProvider.future);
  return DashboardSummary.fromDashboardData(data);
});


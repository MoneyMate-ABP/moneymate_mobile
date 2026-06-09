import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'models/models.dart';
import 'repositories/budget_period_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Menyediakan singleton [BudgetPeriodRepository] yang menggunakan
/// shared [ApiClient].
final budgetPeriodRepositoryProvider = Provider<BudgetPeriodRepository>((ref) {
  return BudgetPeriodRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// FLT-303: Read providers
// ---------------------------------------------------------------------------

/// Mengambil dan mengekspos semua budget period sebagai
/// [AsyncValue<BudgetPeriodListResponse>].
///
/// Usage:
/// ```dart
/// final state = ref.watch(budgetPeriodsProvider);
/// state.when(
///   loading: () => const CircularProgressIndicator(),
///   error:   (err, _) => Text('Error: $err'),
///   data:    (res) => ListView(children: res.data.map((b) => Text(b.name)).toList()),
/// );
/// ```
///
/// Pull-to-refresh:
/// ```dart
/// ref.invalidate(budgetPeriodsProvider);
/// ```
final budgetPeriodsProvider =
    FutureProvider<BudgetPeriodListResponse>((ref) async {
  final repo = ref.watch(budgetPeriodRepositoryProvider);
  return repo.listBudgetPeriods();
});

// ---------------------------------------------------------------------------
// FLT-303: Mutation providers (NotifierProvider)
// ---------------------------------------------------------------------------

/// Notifier untuk operasi mutasi budget period:
/// delete, set-default, update.
///
/// Invalidate [budgetPeriodsProvider] setelah setiap mutasi berhasil
/// agar list otomatis di-refresh.
///
/// Usage:
/// ```dart
/// final notifier = ref.read(budgetPeriodMutationProvider.notifier);
/// await notifier.delete(id);
/// await notifier.setDefault(id);
/// await notifier.update(id, request);
/// ```
class BudgetPeriodMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  BudgetPeriodRepository get _repo =>
      ref.read(budgetPeriodRepositoryProvider);

  /// Menghapus budget period [id] dan me-refresh list.
  Future<void> delete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteBudgetPeriod(id);
      ref.invalidate(budgetPeriodsProvider);
    });
  }

  /// Menetapkan budget period [id] sebagai default dan me-refresh list.
  Future<void> setDefault(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.setDefaultBudgetPeriod(id);
      ref.invalidate(budgetPeriodsProvider);
    });
  }

  /// Memperbarui budget period [id] dan me-refresh list.
  Future<void> update(int id, UpdateBudgetPeriodRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateBudgetPeriod(id, request);
      ref.invalidate(budgetPeriodsProvider);
    });
  }
}

final budgetPeriodMutationProvider =
    AsyncNotifierProvider<BudgetPeriodMutationNotifier, void>(
  BudgetPeriodMutationNotifier.new,
);

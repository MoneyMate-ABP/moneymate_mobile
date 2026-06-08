import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'models/models.dart';
import 'repositories/transaction_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides a singleton [TransactionRepository] backed by the shared
/// [ApiClient].
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Read providers
// ---------------------------------------------------------------------------

/// Fetches all transactions for the current user (no pagination).
///
/// Usage:
/// ```dart
/// final state = ref.watch(transactionsProvider);
/// state.when(
///   loading: () => const CircularProgressIndicator(),
///   error:   (err, _) => Text('Error: $err'),
///   data:    (res) => ListView(children: res.data.map((t) => Text(t.note ?? '')).toList()),
/// );
/// ```
///
/// To re-fetch (e.g. after a mutation):
/// ```dart
/// ref.invalidate(transactionsProvider);
/// ```
final transactionsProvider =
    FutureProvider<TransactionListResponse>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.listTransactions();
});

/// Fetches transactions with the given [TransactionListQuery].
///
/// Keyed by the query object so different filter combinations are cached
/// independently. Pass a [TransactionListQuery] with `page`/`limit` to enable
/// pagination.
///
/// ```dart
/// final query = TransactionListQuery(type: 'expense', page: 1, limit: 20);
/// final state = ref.watch(transactionsQueryProvider(query));
/// ```
final transactionsQueryProvider = FutureProvider.family<
    TransactionListResponse, TransactionListQuery>((ref, query) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.listTransactions(query);
});

/// Fetches a single transaction by ID.
///
/// ```dart
/// final state = ref.watch(transactionByIdProvider(42));
/// ```
final transactionByIdProvider =
    FutureProvider.family<Transaction, int>((ref, id) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionById(id);
});

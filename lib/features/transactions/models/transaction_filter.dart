import 'package:equatable/equatable.dart';

import 'transaction_type.dart';

/// Immutable value-object that holds the current filter state for the
/// transaction list screen.
///
/// A filter is considered "active" when any field is non-null.
class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.type,
    this.categoryName,
    this.searchQuery,
    this.startDate,
    this.endDate,
  });

  /// If non-null, only transactions of this type are shown.
  final TransactionType? type;

  /// If non-null, only transactions whose [Transaction.categoryName] contains
  /// this string (case-insensitive) are shown.
  final String? categoryName;

  /// Free-text search applied to categoryName, note, and amount.
  final String? searchQuery;

  /// Lower bound (inclusive). ISO-8601 date string, e.g. `"2025-06-01"`.
  final DateTime? startDate;

  /// Upper bound (inclusive). ISO-8601 date string, e.g. `"2025-06-30"`.
  final DateTime? endDate;

  /// Returns `true` when at least one filter field is set.
  bool get isActive =>
      type != null ||
      (categoryName != null && categoryName!.isNotEmpty) ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      startDate != null ||
      endDate != null;

  TransactionFilter copyWith({
    Object? type = _keep,
    Object? categoryName = _keep,
    Object? searchQuery = _keep,
    Object? startDate = _keep,
    Object? endDate = _keep,
  }) {
    return TransactionFilter(
      type: type == _keep ? this.type : type as TransactionType?,
      categoryName: categoryName == _keep
          ? this.categoryName
          : categoryName as String?,
      searchQuery:
          searchQuery == _keep ? this.searchQuery : searchQuery as String?,
      startDate: startDate == _keep ? this.startDate : startDate as DateTime?,
      endDate: endDate == _keep ? this.endDate : endDate as DateTime?,
    );
  }

  TransactionFilter clear() => const TransactionFilter();

  @override
  List<Object?> get props =>
      [type, categoryName, searchQuery, startDate, endDate];
}

// Sentinel for copyWith — allows distinguishing "not passed" from "null".
const Object _keep = Object();

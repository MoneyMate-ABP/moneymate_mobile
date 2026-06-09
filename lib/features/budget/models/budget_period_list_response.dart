import 'package:equatable/equatable.dart';

import '../../transactions/models/pagination_meta.dart';
import 'budget_period.dart';

/// Response DTO untuk `GET /api/budget-periods`.
///
/// Tanpa `page`/`limit` params, API mengembalikan:
/// ```json
/// { "data": [ ... ] }
/// ```
///
/// Dengan pagination params:
/// ```json
/// { "data": [ ... ], "meta": { "page": 1, "limit": 10, "total": 5, "total_pages": 1 } }
/// ```
class BudgetPeriodListResponse extends Equatable {
  const BudgetPeriodListResponse({required this.data, this.meta});

  factory BudgetPeriodListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawMeta = json['meta'];

    return BudgetPeriodListResponse(
      data: rawData is List
          ? rawData
              .whereType<Map<String, dynamic>>()
              .map(BudgetPeriod.fromJson)
              .toList()
          : const [],
      meta: rawMeta is Map<String, dynamic>
          ? PaginationMeta.fromJson(rawMeta)
          : null,
    );
  }

  final List<BudgetPeriod> data;

  /// `null` ketika pagination tidak diminta.
  final PaginationMeta? meta;

  @override
  List<Object?> get props => [data, meta];
}

import 'package:equatable/equatable.dart';

import 'pagination_meta.dart';
import 'transaction.dart';

/// Response DTO for `GET /api/transactions`.
///
/// Without `page`/`limit` params the API omits `meta`:
/// ```json
/// { "data": [ ... ] }
/// ```
///
/// With pagination params it includes `meta`:
/// ```json
/// { "data": [ ... ], "meta": { "page": 1, "limit": 20, "total": 87, "total_pages": 5 } }
/// ```
class TransactionListResponse extends Equatable {
  const TransactionListResponse({
    required this.data,
    this.meta,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawMeta = json['meta'];

    return TransactionListResponse(
      data: rawData is List
          ? rawData
              .whereType<Map<String, dynamic>>()
              .map(Transaction.fromJson)
              .toList()
          : const [],
      meta: rawMeta is Map<String, dynamic>
          ? PaginationMeta.fromJson(rawMeta)
          : null,
    );
  }

  final List<Transaction> data;

  /// `null` when pagination was not requested.
  final PaginationMeta? meta;

  @override
  List<Object?> get props => [data, meta];
}

/// Query parameters for `GET /api/transactions`.
///
/// All fields are optional; only non-null values are sent to the API.
class TransactionListQuery {
  const TransactionListQuery({
    this.date,
    this.type,
    this.category,
    this.page,
    this.limit,
  });

  /// Filter by a specific date in `YYYY-MM-DD` format.
  final String? date;

  /// Filter by transaction type (`"income"` or `"expense"`).
  final String? type;

  /// Filter by category ID.
  final int? category;

  /// Page number (1-indexed). Required to enable pagination.
  final int? page;

  /// Page size. Required to enable pagination.
  final int? limit;

  Map<String, Object?> toQueryParameters() {
    return {
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };
  }
}

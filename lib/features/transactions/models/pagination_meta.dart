import 'package:equatable/equatable.dart';

/// Pagination metadata returned when `page` / `limit` query params are used.
///
/// Backend shape (inside `meta`):
/// ```json
/// {
///   "page":        1,
///   "limit":       20,
///   "total":       87,
///   "total_pages": 5
/// }
/// ```
class PaginationMeta extends Equatable {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
      totalPages: _toInt(json['total_pages']),
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'total_pages': totalPages,
      };

  @override
  List<Object?> get props => [page, limit, total, totalPages];

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

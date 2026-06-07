import 'package:equatable/equatable.dart';

import 'transaction_type.dart';

/// Domain model for a single transaction.
///
/// Maps to the object returned inside `data` by:
/// - `GET  /api/transactions`       (list item)
/// - `GET  /api/transactions/:id`   (single item)
/// - `POST /api/transactions`       (created item inside `data`)
/// - `PUT  /api/transactions/:id`   (updated item inside `data`)
///
/// Backend shape:
/// ```json
/// {
///   "id":                 1,
///   "user_id":            42,
///   "category_id":        3,
///   "budget_period_id":   7,          // nullable
///   "type":               "expense",
///   "amount":             50000.0,
///   "note":               "Lunch",    // nullable
///   "date":               "2025-06-07",
///   "latitude":           -6.2,       // nullable
///   "longitude":          106.8,      // nullable
///   "created_at":         "2025-06-07T10:00:00.000Z",
///   "category_name":      "Food",     // nullable (LEFT JOIN)
///   "budget_period_name": "June"      // nullable (LEFT JOIN)
/// }
/// ```
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.budgetPeriodId,
    this.note,
    this.latitude,
    this.longitude,
    this.categoryName,
    this.budgetPeriodName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      categoryId: _toInt(json['category_id']),
      budgetPeriodId: json['budget_period_id'] == null
          ? null
          : _toInt(json['budget_period_id']),
      type: TransactionType.fromJson(json['type'] as String),
      amount: _toDouble(json['amount']),
      note: json['note'] as String?,
      date: json['date'] as String,
      latitude: json['latitude'] == null ? null : _toDouble(json['latitude']),
      longitude:
          json['longitude'] == null ? null : _toDouble(json['longitude']),
      createdAt: json['created_at'] as String,
      categoryName: json['category_name'] as String?,
      budgetPeriodName: json['budget_period_name'] as String?,
    );
  }

  final int id;
  final int userId;
  final int categoryId;
  final int? budgetPeriodId;
  final TransactionType type;
  final double amount;
  final String? note;

  /// ISO-8601 date string, e.g. `"2025-06-07"`.
  final String date;
  final double? latitude;
  final double? longitude;

  /// ISO-8601 datetime string as returned by the API.
  final String createdAt;

  /// Joined from the `categories` table. May be `null` when the LEFT JOIN
  /// finds no matching row (e.g. category was deleted).
  final String? categoryName;

  /// Joined from the `budget_periods` table. `null` when no period is linked.
  final String? budgetPeriodName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'budget_period_id': budgetPeriodId,
        'type': type.toJson(),
        'amount': amount,
        'note': note,
        'date': date,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt,
        'category_name': categoryName,
        'budget_period_name': budgetPeriodName,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        budgetPeriodId,
        type,
        amount,
        note,
        date,
        latitude,
        longitude,
        createdAt,
        categoryName,
        budgetPeriodName,
      ];

  // ---- helpers ---------------------------------------------------------------

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}

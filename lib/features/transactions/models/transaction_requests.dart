import 'transaction_type.dart';

/// Request DTO for `POST /api/transactions`.
///
/// Backend Zod schema:
/// ```
/// category_id      : number (positive int)  — required
/// budget_period_id : number (positive int)  — optional, null → use default period
/// type             : "income" | "expense"   — required
/// amount           : number (positive)      — required
/// note             : string (max 1000)      — optional / nullable
/// date             : string (non-empty)     — required  e.g. "2025-06-07"
/// latitude         : number (-90..90)       — optional / nullable
/// longitude        : number (-180..180)     — optional / nullable
/// ```
///
/// Omit [budgetPeriodId] entirely to let the server use the user's default
/// budget period. Pass `null` explicitly to store the transaction without
/// any period.
class CreateTransactionRequest {
  const CreateTransactionRequest({
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.budgetPeriodId = _omit,
    this.note,
    this.latitude,
    this.longitude,
  });

  // Sentinel that lets us distinguish "not provided" from "explicit null".
  // The const constructor default keeps it private.
  static const Object _omit = Object();

  final int categoryId;

  /// Use [_omit] (the default) to omit the field and let the server pick the
  /// default budget period. Pass `null` to explicitly clear the period.
  final Object? budgetPeriodId;

  final TransactionType type;
  final double amount;
  final String? note;

  /// Required. ISO-8601 date string, e.g. `"2025-06-07"`.
  final String date;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'type': type.toJson(),
      'amount': amount,
      'date': date,
      if (budgetPeriodId != _omit) 'budget_period_id': budgetPeriodId,
      if (note != null) 'note': note,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

/// Request DTO for `PUT /api/transactions/:id`.
///
/// At least one field must be non-null (enforced by the backend).
///
/// Backend Zod schema (all fields optional):
/// ```
/// category_id      : number (positive int)  — optional
/// budget_period_id : number | null          — optional / nullable
/// type             : "income" | "expense"   — optional
/// amount           : number (positive)      — optional
/// note             : string (max 1000)      — optional / nullable
/// date             : string                 — optional
/// latitude         : number (-90..90)       — optional / nullable
/// longitude        : number (-180..180)     — optional / nullable
/// ```
class UpdateTransactionRequest {
  const UpdateTransactionRequest({
    this.categoryId,
    this.budgetPeriodId,
    this.type,
    this.amount,
    this.note,
    this.date,
    this.latitude,
    this.longitude,
  });

  final int? categoryId;
  final int? budgetPeriodId;
  final TransactionType? type;
  final double? amount;
  final String? note;

  /// ISO-8601 date string, e.g. `"2025-06-07"`.
  final String? date;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'category_id': categoryId,
      if (budgetPeriodId != null) 'budget_period_id': budgetPeriodId,
      if (type != null) 'type': type!.toJson(),
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

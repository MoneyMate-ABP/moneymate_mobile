/// Mirrors the `type` field accepted by `POST /api/transactions`
/// and returned by `GET /api/transactions` / `GET /api/transactions/:id`.
enum TransactionType {
  income,
  expense;

  /// Deserialise from the raw API string value.
  ///
  /// Throws [ArgumentError] for unknown values.
  static TransactionType fromJson(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => throw ArgumentError('Unknown TransactionType: "$value"'),
    };
  }

  /// Serialise to the raw API string value.
  String toJson() => name; // 'income' | 'expense'
}

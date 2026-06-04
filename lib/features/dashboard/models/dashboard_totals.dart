import 'package:equatable/equatable.dart';

/// Maps to the `data.totals` object returned by `GET /api/dashboard`.
///
/// Backend shape:
/// ```json
/// {
///   "balance": 5000000.0,
///   "income":  8000000.0,
///   "expense": 3000000.0
/// }
/// ```
class DashboardTotals extends Equatable {
  const DashboardTotals({
    required this.balance,
    required this.income,
    required this.expense,
  });

  factory DashboardTotals.fromJson(Map<String, dynamic> json) {
    return DashboardTotals(
      balance: _toDouble(json['balance']),
      income: _toDouble(json['income']),
      expense: _toDouble(json['expense']),
    );
  }

  final double balance;
  final double income;
  final double expense;

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'income': income,
        'expense': expense,
      };

  @override
  List<Object?> get props => [balance, income, expense];

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}

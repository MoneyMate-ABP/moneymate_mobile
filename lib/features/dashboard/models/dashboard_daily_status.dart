import 'package:equatable/equatable.dart';

/// Maps to the `daily_status` object inside each budget period entry
/// returned by `GET /api/dashboard`.
///
/// Backend shape (from `getDailyStatus` / `getDailyStatusesInRange`):
/// ```json
/// {
///   "date":             "2025-06-04",
///   "budget_system":    "carry_over",
///   "base":             150000.0,
///   "carry_over":       20000.0,
///   "invested_before":  0.0,
///   "invested_today":   0.0,
///   "invested_total":   0.0,
///   "effective_budget": 170000.0,
///   "total_spent":      90000.0,
///   "remaining":        80000.0,
///   "is_excluded_day":  false,
///   "is_weekend":       false
/// }
/// ```
class DashboardDailyStatus extends Equatable {
  const DashboardDailyStatus({
    required this.date,
    required this.budgetSystem,
    required this.base,
    required this.carryOver,
    required this.investedBefore,
    required this.investedToday,
    required this.investedTotal,
    required this.effectiveBudget,
    required this.totalSpent,
    required this.remaining,
    required this.isExcludedDay,
    required this.isWeekend,
  });

  factory DashboardDailyStatus.fromJson(Map<String, dynamic> json) {
    return DashboardDailyStatus(
      date: '${json['date'] ?? ''}',
      budgetSystem: '${json['budget_system'] ?? 'nothing'}',
      base: _toDouble(json['base']),
      carryOver: _toDouble(json['carry_over']),
      investedBefore: _toDouble(json['invested_before']),
      investedToday: _toDouble(json['invested_today']),
      investedTotal: _toDouble(json['invested_total']),
      effectiveBudget: _toDouble(json['effective_budget']),
      totalSpent: _toDouble(json['total_spent']),
      remaining: _toDouble(json['remaining']),
      isExcludedDay: json['is_excluded_day'] == true,
      isWeekend: json['is_weekend'] == true,
    );
  }

  /// Date string in `yyyy-MM-dd` format.
  final String date;

  /// Budget system identifier: `carry_over`, `invest`, or `nothing`.
  final String budgetSystem;

  /// Base daily budget before any carry-over is applied.
  final double base;

  /// Carry-over amount added to today's effective budget.
  final double carryOver;

  /// Invested amount accumulated before today.
  final double investedBefore;

  /// Invested amount for today (only relevant when `budgetSystem == 'invest'`).
  final double investedToday;

  /// Total invested amount up to and including today.
  final double investedTotal;

  /// Effective budget = base + carryOver.
  final double effectiveBudget;

  /// Total spending recorded for this date.
  final double totalSpent;

  /// Remaining = effectiveBudget - totalSpent.
  final double remaining;

  /// Whether this day is excluded from budget counting.
  final bool isExcludedDay;

  /// Whether this day falls on a weekend.
  final bool isWeekend;

  Map<String, dynamic> toJson() => {
        'date': date,
        'budget_system': budgetSystem,
        'base': base,
        'carry_over': carryOver,
        'invested_before': investedBefore,
        'invested_today': investedToday,
        'invested_total': investedTotal,
        'effective_budget': effectiveBudget,
        'total_spent': totalSpent,
        'remaining': remaining,
        'is_excluded_day': isExcludedDay,
        'is_weekend': isWeekend,
      };

  @override
  List<Object?> get props => [
        date,
        budgetSystem,
        base,
        carryOver,
        investedBefore,
        investedToday,
        investedTotal,
        effectiveBudget,
        totalSpent,
        remaining,
        isExcludedDay,
        isWeekend,
      ];

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}

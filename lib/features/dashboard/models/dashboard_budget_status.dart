import 'package:equatable/equatable.dart';

import 'dashboard_daily_status.dart';

/// Maps to one item inside `data.budgets.status[]` returned by
/// `GET /api/dashboard`.
///
/// Backend shape:
/// ```json
/// {
///   "budget_period_id": 3,
///   "name":             "Juni 2025",
///   "budget_system":    "carry_over",
///   "category_id":      null,
///   "category_name":    null,
///   "category_type":    null,
///   "start_date":       "2025-06-01",
///   "end_date":         "2025-06-30",
///   "daily_status":     { ... }
/// }
/// ```
class DashboardBudgetStatus extends Equatable {
  const DashboardBudgetStatus({
    required this.budgetPeriodId,
    required this.name,
    required this.budgetSystem,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.startDate,
    required this.endDate,
    required this.dailyStatus,
  });

  factory DashboardBudgetStatus.fromJson(Map<String, dynamic> json) {
    final rawDailyStatus = json['daily_status'];
    return DashboardBudgetStatus(
      budgetPeriodId: _toInt(json['budget_period_id']),
      name: '${json['name'] ?? ''}',
      budgetSystem: '${json['budget_system'] ?? 'nothing'}',
      categoryId: _toIntOrNull(json['category_id']),
      categoryName: json['category_name'] != null
          ? '${json['category_name']}'
          : null,
      categoryType: json['category_type'] != null
          ? '${json['category_type']}'
          : null,
      startDate: '${json['start_date'] ?? ''}',
      endDate: '${json['end_date'] ?? ''}',
      dailyStatus: rawDailyStatus is Map<String, dynamic>
          ? DashboardDailyStatus.fromJson(rawDailyStatus)
          : null,
    );
  }

  /// ID of the associated budget period.
  final int budgetPeriodId;

  /// User-defined name of the budget period.
  final String name;

  /// Budget system: `carry_over`, `invest`, or `nothing`.
  final String budgetSystem;

  /// Linked category ID, or `null` if the budget covers all categories.
  final int? categoryId;

  /// Linked category name, or `null`.
  final String? categoryName;

  /// Linked category type (`income` / `expense`), or `null`.
  final String? categoryType;

  /// Budget period start date (`yyyy-MM-dd`).
  final String startDate;

  /// Budget period end date (`yyyy-MM-dd`).
  final String endDate;

  /// Today's computed daily status for this budget period, or `null` if the
  /// backend did not return a daily_status for this date.
  final DashboardDailyStatus? dailyStatus;

  Map<String, dynamic> toJson() => {
        'budget_period_id': budgetPeriodId,
        'name': name,
        'budget_system': budgetSystem,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_type': categoryType,
        'start_date': startDate,
        'end_date': endDate,
        'daily_status': dailyStatus?.toJson(),
      };

  @override
  List<Object?> get props => [
        budgetPeriodId,
        name,
        budgetSystem,
        categoryId,
        categoryName,
        categoryType,
        startDate,
        endDate,
        dailyStatus,
      ];

  static int _toInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static int? _toIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }
}

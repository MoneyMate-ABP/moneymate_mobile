import 'package:equatable/equatable.dart';

import 'dashboard_budget_status.dart';

/// Maps to the `data.budgets` object returned by `GET /api/dashboard`.
///
/// Backend shape:
/// ```json
/// {
///   "active_count":    2,
///   "effective_today": 340000.0,
///   "spent_today":     180000.0,
///   "remaining_today": 160000.0,
///   "status":          [ ... ]
/// }
/// ```
class DashboardBudgets extends Equatable {
  const DashboardBudgets({
    required this.activeCount,
    required this.effectiveToday,
    required this.spentToday,
    required this.remainingToday,
    required this.status,
  });

  factory DashboardBudgets.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final statusList = rawStatus is List
        ? rawStatus
            .whereType<Map<String, dynamic>>()
            .map(DashboardBudgetStatus.fromJson)
            .toList()
        : <DashboardBudgetStatus>[];

    return DashboardBudgets(
      activeCount: _toInt(json['active_count']),
      effectiveToday: _toDouble(json['effective_today']),
      spentToday: _toDouble(json['spent_today']),
      remainingToday: _toDouble(json['remaining_today']),
      status: statusList,
    );
  }

  /// Number of active budget periods as of today.
  final int activeCount;

  /// Sum of effective budgets across all active periods for today.
  final double effectiveToday;

  /// Sum of spending across all active periods for today.
  final double spentToday;

  /// Sum of remaining budgets across all active periods for today.
  final double remainingToday;

  /// Detailed status per active budget period.
  final List<DashboardBudgetStatus> status;

  Map<String, dynamic> toJson() => {
        'active_count': activeCount,
        'effective_today': effectiveToday,
        'spent_today': spentToday,
        'remaining_today': remainingToday,
        'status': status.map((s) => s.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        activeCount,
        effectiveToday,
        spentToday,
        remainingToday,
        status,
      ];

  static int _toInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}

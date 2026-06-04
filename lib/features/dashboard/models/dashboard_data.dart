import 'package:equatable/equatable.dart';

import 'dashboard_budgets.dart';
import 'dashboard_totals.dart';

// TODO(FLT-301): The current `GET /api/dashboard` endpoint returns only
// `totals` and `budgets`. Recent transactions are NOT included in the
// dashboard response. Confirm with backend whether:
//   1. A `recent_transactions` field will be added to `GET /api/dashboard`, or
//   2. The mobile app should call `GET /api/transactions` with a limit param.
// Until confirmed, recent_transactions support is omitted from this model.

/// Top-level DTO for the dashboard API response.
///
/// Maps to the full `data` object returned by `GET /api/dashboard`:
/// ```json
/// {
///   "data": {
///     "totals": { "balance": 5000000, "income": 8000000, "expense": 3000000 },
///     "budgets": {
///       "active_count":    2,
///       "effective_today": 340000,
///       "spent_today":     180000,
///       "remaining_today": 160000,
///       "status":          [ ... ]
///     }
///   }
/// }
/// ```
class DashboardData extends Equatable {
  const DashboardData({
    required this.totals,
    required this.budgets,
  });

  /// Parse the top-level `data` key of the API response.
  ///
  /// Usage:
  /// ```dart
  /// final body = response.body as Map<String, dynamic>;
  /// final data = DashboardData.fromJson(body['data'] as Map<String, dynamic>);
  /// ```
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final rawTotals = json['totals'];
    final rawBudgets = json['budgets'];

    return DashboardData(
      totals: rawTotals is Map<String, dynamic>
          ? DashboardTotals.fromJson(rawTotals)
          : const DashboardTotals(balance: 0, income: 0, expense: 0),
      budgets: rawBudgets is Map<String, dynamic>
          ? DashboardBudgets.fromJson(rawBudgets)
          : const DashboardBudgets(
              activeCount: 0,
              effectiveToday: 0,
              spentToday: 0,
              remainingToday: 0,
              status: [],
            ),
    );
  }

  /// Financial totals: balance, total income, total expense.
  final DashboardTotals totals;

  /// Budget summary for today, including per-period statuses.
  final DashboardBudgets budgets;

  Map<String, dynamic> toJson() => {
        'totals': totals.toJson(),
        'budgets': budgets.toJson(),
      };

  @override
  List<Object?> get props => [totals, budgets];
}

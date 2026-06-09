import 'package:equatable/equatable.dart';

import 'dashboard_data.dart';

/// FLT-302: Ringkasan keuangan dashboard.
///
/// Diturunkan dari [DashboardData] yang dikembalikan oleh
/// `GET /api/dashboard`. Menyatukan:
/// - [totalBalance]    → `data.totals.balance`
/// - [totalIncome]     → `data.totals.income`
/// - [totalExpense]    → `data.totals.expense`
/// - [todayExpense]    → `data.budgets.spentToday`
/// - [todayRemaining]  → `data.totals.balance - data.budgets.spentToday`
///
/// ```dart
/// final summary = DashboardSummary.fromDashboardData(data);
/// print(summary.totalBalance);   // e.g. 5000000.0
/// print(summary.todayExpense);   // e.g. 180000.0
/// print(summary.todayRemaining); // e.g. 4820000.0
/// ```
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todayExpense,
    required this.todayRemaining,
  });

  /// Bangun [DashboardSummary] dari respons API dashboard.
  ///
  /// - [todayExpense]   = `budgets.spentToday` (total pengeluaran hari ini
  ///   dari seluruh budget period yang aktif).
  /// - [todayRemaining] = `totals.balance - budgets.spentToday`
  ///   (sisa saldo setelah dikurangi pengeluaran hari ini).
  factory DashboardSummary.fromDashboardData(DashboardData data) {
    final todayExpense = data.budgets.spentToday;
    final todayRemaining = data.totals.balance - todayExpense;
    return DashboardSummary(
      totalBalance: data.totals.balance,
      totalIncome: data.totals.income,
      totalExpense: data.totals.expense,
      todayExpense: todayExpense,
      todayRemaining: todayRemaining,
    );
  }

  /// Total saldo (balance all-time).
  final double totalBalance;

  /// Total pemasukan (all-time income).
  final double totalIncome;

  /// Total pengeluaran (all-time expense).
  final double totalExpense;

  /// Pengeluaran hari ini (dari seluruh budget period aktif).
  final double todayExpense;

  /// Sisa saldo hari ini = totalBalance - todayExpense.
  final double todayRemaining;

  @override
  List<Object?> get props => [
        totalBalance,
        totalIncome,
        totalExpense,
        todayExpense,
        todayRemaining,
      ];
}

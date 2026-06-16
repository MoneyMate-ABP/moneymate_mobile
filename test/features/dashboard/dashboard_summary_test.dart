// ignore_for_file: prefer_const_constructors, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/features/dashboard/models/dashboard_budgets.dart';
import 'package:moneymate_mobile/features/dashboard/models/dashboard_data.dart';
import 'package:moneymate_mobile/features/dashboard/models/dashboard_summary.dart';
import 'package:moneymate_mobile/features/dashboard/models/dashboard_totals.dart';

/// FLT-302: Unit tests for [DashboardSummary].
///
/// Checklist:
/// - [x] Summary saldo tampil benar (totalBalance)
/// - [x] Pemasukan terhitung benar (totalIncome)
/// - [x] Pengeluaran terhitung benar (totalExpense)
/// - [x] Pengeluaran hari ini sesuai transaksi tanggal hari ini (todayExpense)
/// - [x] Sisa saldo hari ini sesuai perhitungan (todayRemaining)
/// - [x] Empty state: semua nilai nol menghasilkan summary zeroed
/// - [x] Negatif: todayExpense > balance menghasilkan todayRemaining negatif
/// - [x] Equatable: dua summary dengan nilai sama dianggap equal
void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DashboardData _makeDashboardData({
    double balance = 0,
    double income = 0,
    double expense = 0,
    double spentToday = 0,
    double remainingToday = 0,
  }) {
    return DashboardData(
      totals: DashboardTotals(
        balance: balance,
        income: income,
        expense: expense,
      ),
      budgets: DashboardBudgets(
        activeCount: 1,
        effectiveToday: 0,
        spentToday: spentToday,
        remainingToday: remainingToday,
        status: const [],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DashboardSummary.fromDashboardData – nilai normal
  // ---------------------------------------------------------------------------

  group('DashboardSummary.fromDashboardData – nilai normal', () {
    test('totalBalance sesuai data.totals.balance', () {
      final data = _makeDashboardData(balance: 5_000_000);
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.totalBalance, 5_000_000.0);
    });

    test('totalIncome sesuai data.totals.income', () {
      final data = _makeDashboardData(income: 8_000_000);
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.totalIncome, 8_000_000.0);
    });

    test('totalExpense sesuai data.totals.expense', () {
      final data = _makeDashboardData(expense: 3_000_000);
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.totalExpense, 3_000_000.0);
    });

    test('todayExpense sesuai data.budgets.spentToday', () {
      final data = _makeDashboardData(spentToday: 180_000);
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.todayExpense, 180_000.0);
    });

    test('todayRemaining = totalBalance - todayExpense', () {
      final data = _makeDashboardData(
        balance: 5_000_000,
        spentToday: 180_000,
      );
      final summary = DashboardSummary.fromDashboardData(data);

      // Sisa saldo hari ini = 5.000.000 - 180.000 = 4.820.000
      expect(summary.todayRemaining, 4_820_000.0);
    });

    test('semua field terisi dari satu DashboardData', () {
      final data = _makeDashboardData(
        balance: 5_000_000,
        income: 8_000_000,
        expense: 3_000_000,
        spentToday: 180_000,
      );
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.totalBalance, 5_000_000.0);
      expect(summary.totalIncome, 8_000_000.0);
      expect(summary.totalExpense, 3_000_000.0);
      expect(summary.todayExpense, 180_000.0);
      expect(summary.todayRemaining, 4_820_000.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Empty state – semua nilai nol
  // ---------------------------------------------------------------------------

  group('Empty state – semua nilai nol', () {
    test('DashboardSummary zeroed ketika DashboardData kosong', () {
      final data = _makeDashboardData(); // semua 0
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.totalBalance, 0.0);
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.todayExpense, 0.0);
      expect(summary.todayRemaining, 0.0); // 0 - 0 = 0
    });
  });

  // ---------------------------------------------------------------------------
  // Edge case: todayExpense melebihi balance (saldo minus)
  // ---------------------------------------------------------------------------

  group('Edge case – todayExpense > balance', () {
    test('todayRemaining bernilai negatif jika pengeluaran melebihi saldo', () {
      final data = _makeDashboardData(
        balance: 100_000,
        spentToday: 300_000, // pengeluaran 300k > saldo 100k
      );
      final summary = DashboardSummary.fromDashboardData(data);

      // todayRemaining = 100.000 - 300.000 = -200.000
      expect(summary.todayRemaining, -200_000.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  group('Equatable', () {
    test('dua DashboardSummary dengan nilai sama dianggap equal', () {
      const s1 = DashboardSummary(
        totalBalance: 5_000_000,
        totalIncome: 8_000_000,
        totalExpense: 3_000_000,
        todayExpense: 180_000,
        todayRemaining: 4_820_000,
      );
      const s2 = DashboardSummary(
        totalBalance: 5_000_000,
        totalIncome: 8_000_000,
        totalExpense: 3_000_000,
        todayExpense: 180_000,
        todayRemaining: 4_820_000,
      );

      expect(s1, equals(s2));
    });

    test('dua DashboardSummary dengan nilai berbeda tidak equal', () {
      const s1 = DashboardSummary(
        totalBalance: 5_000_000,
        totalIncome: 8_000_000,
        totalExpense: 3_000_000,
        todayExpense: 180_000,
        todayRemaining: 4_820_000,
      );
      const s2 = DashboardSummary(
        totalBalance: 1_000_000, // beda
        totalIncome: 8_000_000,
        totalExpense: 3_000_000,
        todayExpense: 180_000,
        todayRemaining: 820_000,
      );

      expect(s1, isNot(equals(s2)));
    });
  });

  // ---------------------------------------------------------------------------
  // DashboardTotals.fromJson – parsing
  // ---------------------------------------------------------------------------

  group('DashboardTotals.fromJson – parsing JSON', () {
    test('parsing dari int fields (respons API integer)', () {
      final totals = DashboardTotals.fromJson({
        'balance': 5000000,
        'income': 8000000,
        'expense': 3000000,
      });

      expect(totals.balance, 5_000_000.0);
      expect(totals.income, 8_000_000.0);
      expect(totals.expense, 3_000_000.0);
    });

    test('parsing dari double fields', () {
      final totals = DashboardTotals.fromJson({
        'balance': 5000000.5,
        'income': 8000000.0,
        'expense': 3000000.0,
      });

      expect(totals.balance, 5_000_000.5);
    });

    test('null fields menggunakan nilai default 0.0', () {
      final totals = DashboardTotals.fromJson({});

      expect(totals.balance, 0.0);
      expect(totals.income, 0.0);
      expect(totals.expense, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // DashboardData.fromJson – end-to-end parsing
  // ---------------------------------------------------------------------------

  group('DashboardData.fromJson – end-to-end', () {
    test('parse respons API dashboard lengkap dan summary benar', () {
      final json = {
        'totals': {
          'balance': 5000000.0,
          'income': 8000000.0,
          'expense': 3000000.0,
        },
        'budgets': {
          'active_count': 2,
          'effective_today': 340000.0,
          'spent_today': 180000.0,
          'remaining_today': 160000.0,
          'status': <dynamic>[],
        },
      };

      final data = DashboardData.fromJson(json);
      final summary = DashboardSummary.fromDashboardData(data);

      expect(summary.totalBalance, 5_000_000.0);
      expect(summary.totalIncome, 8_000_000.0);
      expect(summary.totalExpense, 3_000_000.0);
      expect(summary.todayExpense, 180_000.0);
      expect(summary.todayRemaining, 4_820_000.0); // 5jt - 180rb
    });

    test('parse dengan data budgets null menggunakan nilai default', () {
      final json = {
        'totals': {
          'balance': 1000000.0,
          'income': 1000000.0,
          'expense': 0.0,
        },
        // budgets tidak ada
      };

      final data = DashboardData.fromJson(json);
      final summary = DashboardSummary.fromDashboardData(data);

      // budgets.spentToday default ke 0
      expect(summary.todayExpense, 0.0);
      expect(summary.todayRemaining, 1_000_000.0);
    });
  });
}

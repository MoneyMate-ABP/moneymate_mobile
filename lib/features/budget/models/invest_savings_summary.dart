import 'package:equatable/equatable.dart';

class InvestSavingsSummary extends Equatable {
  const InvestSavingsSummary({
    required this.totalInvested,
    required this.periodCount,
    required this.periods,
  });

  factory InvestSavingsSummary.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['periods'];
    final periodsList = rawPeriods is List
        ? rawPeriods
            .whereType<Map<String, dynamic>>()
            .map(InvestSavingsPeriod.fromJson)
            .toList()
        : <InvestSavingsPeriod>[];

    return InvestSavingsSummary(
      totalInvested: _toDouble(json['total_invested']),
      periodCount: _toInt(json['period_count']),
      periods: periodsList,
    );
  }

  final double totalInvested;
  final int periodCount;
  final List<InvestSavingsPeriod> periods;

  Map<String, dynamic> toJson() => {
        'total_invested': totalInvested,
        'period_count': periodCount,
        'periods': periods.map((p) => p.toJson()).toList(),
      };

  @override
  List<Object?> get props => [totalInvested, periodCount, periods];

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  static int _toInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

class InvestSavingsPeriod extends Equatable {
  const InvestSavingsPeriod({
    required this.budgetPeriodId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
    required this.dailyBudgetBase,
    required this.investedTotal,
    required this.trackedDays,
    this.categoryId,
    this.categoryName,
    this.categoryType,
    this.trackedStartDate,
    this.trackedEndDate,
  });

  factory InvestSavingsPeriod.fromJson(Map<String, dynamic> json) {
    return InvestSavingsPeriod(
      budgetPeriodId: _toInt(json['budget_period_id']),
      name: '${json['name'] ?? ''}',
      startDate: '${json['start_date'] ?? ''}',
      endDate: '${json['end_date'] ?? ''}',
      totalBudget: _toDouble(json['total_budget']),
      dailyBudgetBase: _toDouble(json['daily_budget_base']),
      investedTotal: _toDouble(json['invested_total']),
      trackedDays: _toInt(json['tracked_days']),
      categoryId: json['category_id'] == null ? null : _toInt(json['category_id']),
      categoryName: json['category_name'] as String?,
      categoryType: json['category_type'] as String?,
      trackedStartDate: json['tracked_start_date'] as String?,
      trackedEndDate: json['tracked_end_date'] as String?,
    );
  }

  final int budgetPeriodId;
  final String name;
  final String startDate;
  final String endDate;
  final double totalBudget;
  final double dailyBudgetBase;
  final double investedTotal;
  final int trackedDays;
  final int? categoryId;
  final String? categoryName;
  final String? categoryType;
  final String? trackedStartDate;
  final String? trackedEndDate;

  Map<String, dynamic> toJson() => {
        'budget_period_id': budgetPeriodId,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'total_budget': totalBudget,
        'daily_budget_base': dailyBudgetBase,
        'invested_total': investedTotal,
        'tracked_days': trackedDays,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_type': categoryType,
        'tracked_start_date': trackedStartDate,
        'tracked_end_date': trackedEndDate,
      };

  @override
  List<Object?> get props => [
        budgetPeriodId,
        name,
        startDate,
        endDate,
        totalBudget,
        dailyBudgetBase,
        investedTotal,
        trackedDays,
        categoryId,
        categoryName,
        categoryType,
        trackedStartDate,
        trackedEndDate,
      ];

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  static int _toInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

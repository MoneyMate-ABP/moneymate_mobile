import 'package:equatable/equatable.dart';

/// Domain model untuk satu Budget Period.
///
/// Maps ke objek yang dikembalikan oleh:
/// - `GET  /api/budget-periods`       (list item)
/// - `PUT  /api/budget-periods/:id`   (updated item)
/// - `POST /api/budget-periods/:id/set-default` (updated item)
///
/// Backend shape (dari `toBudgetPeriodResponse` di `budgetPeriodController.js`):
/// ```json
/// {
///   "id":                  1,
///   "user_id":             42,
///   "category_id":         null,
///   "category_name":       null,
///   "category_type":       null,
///   "name":                "Juni 2025",
///   "total_budget":        3000000.0,
///   "daily_budget_base":   150000.0,
///   "start_date":          "2025-06-01",
///   "end_date":            "2025-06-30",
///   "working_days_count":  20,
///   "excluded_weekdays":   [0, 6],
///   "budget_system":       "carry_over",
///   "is_default":          true,
///   "created_at":          "2025-05-31T10:00:00.000Z"
/// }
/// ```
class BudgetPeriod extends Equatable {
  const BudgetPeriod({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalBudget,
    required this.dailyBudgetBase,
    required this.startDate,
    required this.endDate,
    required this.workingDaysCount,
    required this.excludedWeekdays,
    required this.budgetSystem,
    required this.isDefault,
    required this.createdAt,
    this.categoryId,
    this.categoryName,
    this.categoryType,
  });

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) {
    // excluded_weekdays datang sebagai List (sudah di-parse oleh backend).
    final rawExcluded = json['excluded_weekdays'];
    final excludedWeekdays = rawExcluded is List
        ? rawExcluded.map((e) => _toInt(e)).toList()
        : <int>[];

    return BudgetPeriod(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      categoryId:
          json['category_id'] == null ? null : _toInt(json['category_id']),
      categoryName: json['category_name'] as String?,
      categoryType: json['category_type'] as String?,
      name: '${json['name'] ?? ''}',
      totalBudget: _toDouble(json['total_budget']),
      dailyBudgetBase: _toDouble(json['daily_budget_base']),
      startDate: '${json['start_date'] ?? ''}',
      endDate: '${json['end_date'] ?? ''}',
      workingDaysCount: _toInt(json['working_days_count']),
      excludedWeekdays: excludedWeekdays,
      budgetSystem: '${json['budget_system'] ?? 'nothing'}',
      isDefault: json['is_default'] == true,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }

  final int id;
  final int userId;

  /// Linked category ID, atau `null` jika budget mencakup semua kategori.
  final int? categoryId;

  /// Nama kategori dari LEFT JOIN. `null` jika tidak ada kategori.
  final String? categoryName;

  /// Tipe kategori (`income` / `expense` / `both`). `null` jika tidak ada.
  final String? categoryType;

  /// Nama budget period buatan user.
  final String name;

  /// Total anggaran keseluruhan periode.
  final double totalBudget;

  /// Anggaran harian = totalBudget / workingDaysCount.
  final double dailyBudgetBase;

  /// Tanggal mulai dalam format `yyyy-MM-dd`.
  final String startDate;

  /// Tanggal selesai dalam format `yyyy-MM-dd`.
  final String endDate;

  /// Jumlah hari kerja dalam periode (tidak termasuk [excludedWeekdays]).
  final int workingDaysCount;

  /// Hari-hari yang dikecualikan (0=Minggu, 6=Sabtu). Default: `[0, 6]`.
  final List<int> excludedWeekdays;

  /// Sistem budget: `carry_over`, `invest`, atau `nothing`.
  final String budgetSystem;

  /// Apakah ini budget period default.
  final bool isDefault;

  /// ISO-8601 datetime string dari DB.
  final String createdAt;

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` jika `endDate` >= hari ini (budget masih aktif).
  bool get isActive {
    try {
      final end = DateTime.parse(endDate);
      final today = DateTime.now();
      // Bandingkan tanggal saja, abaikan waktu.
      final todayDate = DateTime(today.year, today.month, today.day);
      final endDate0 = DateTime(end.year, end.month, end.day);
      return !endDate0.isBefore(todayDate);
    } catch (_) {
      return false;
    }
  }

  /// Mengembalikan label status: `'Aktif'` atau `'Selesai'`.
  String get statusLabel => isActive ? 'Aktif' : 'Selesai';

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_type': categoryType,
        'name': name,
        'total_budget': totalBudget,
        'daily_budget_base': dailyBudgetBase,
        'start_date': startDate,
        'end_date': endDate,
        'working_days_count': workingDaysCount,
        'excluded_weekdays': excludedWeekdays,
        'budget_system': budgetSystem,
        'is_default': isDefault,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        categoryName,
        categoryType,
        name,
        totalBudget,
        dailyBudgetBase,
        startDate,
        endDate,
        workingDaysCount,
        excludedWeekdays,
        budgetSystem,
        isDefault,
        createdAt,
      ];

  // ---- helpers ---------------------------------------------------------------

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}

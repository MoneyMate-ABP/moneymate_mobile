/// Request DTO untuk `POST /api/budget-periods`.
///
/// Disiapkan untuk Sprint berikutnya (Create Budget Period).
///
/// Backend Zod schema (`budgetPeriodController.js:32–41`):
/// ```
/// category_id:       number (nullable, optional)
/// name:              string (min:1, max:150, required)
/// total_budget:      number (positive, required)
/// start_date:        string (min:1, required) — format YYYY-MM-DD
/// end_date:          string (min:1, required) — format YYYY-MM-DD
/// excluded_weekdays: number[] (0-6, default:[0,6])
/// budget_system:     enum("carry_over","invest","nothing", default:"nothing")
/// is_default:        boolean (default:false)
/// ```
class CreateBudgetPeriodRequest {
  const CreateBudgetPeriodRequest({
    required this.name,
    required this.totalBudget,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.excludedWeekdays = const [0, 6],
    this.budgetSystem = 'nothing',
    this.isDefault = false,
  });

  final String name;
  final double totalBudget;

  /// Format `YYYY-MM-DD`.
  final String startDate;

  /// Format `YYYY-MM-DD`.
  final String endDate;

  final int? categoryId;

  /// Hari yang dikecualikan (0=Minggu, 6=Sabtu). Default: `[0, 6]`.
  final List<int> excludedWeekdays;

  /// `'carry_over'`, `'invest'`, atau `'nothing'`.
  final String budgetSystem;

  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'name': name,
        'total_budget': totalBudget,
        'start_date': startDate,
        'end_date': endDate,
        if (categoryId != null) 'category_id': categoryId,
        'excluded_weekdays': excludedWeekdays,
        'budget_system': budgetSystem,
        'is_default': isDefault,
      };
}

/// Request DTO untuk `PUT /api/budget-periods/:id`.
///
/// Semua field opsional — backend memerlukan minimal satu field.
///
/// Backend Zod schema (`budgetPeriodController.js:43–56`):
/// ```
/// category_id:       number (nullable, optional)
/// name:              string (min:1, max:150, optional)
/// total_budget:      number (positive, optional)
/// start_date:        string (optional)
/// end_date:          string (optional)
/// excluded_weekdays: number[] (0-6, optional)
/// budget_system:     enum("carry_over","invest","nothing", optional)
/// is_default:        boolean (optional)
/// ```
class UpdateBudgetPeriodRequest {
  const UpdateBudgetPeriodRequest({
    this.name,
    this.totalBudget,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.excludedWeekdays,
    this.budgetSystem,
    this.isDefault,
  });

  final String? name;
  final double? totalBudget;
  final String? startDate;
  final String? endDate;
  final int? categoryId;
  final List<int>? excludedWeekdays;
  final String? budgetSystem;
  final bool? isDefault;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (totalBudget != null) 'total_budget': totalBudget,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (categoryId != null) 'category_id': categoryId,
        if (excludedWeekdays != null) 'excluded_weekdays': excludedWeekdays,
        if (budgetSystem != null) 'budget_system': budgetSystem,
        if (isDefault != null) 'is_default': isDefault,
      };
}

/// Query parameters untuk `GET /api/budget-periods`.
///
/// Semua field opsional; hanya nilai non-null yang dikirim.
class BudgetPeriodListQuery {
  const BudgetPeriodListQuery({this.page, this.limit});

  /// Nomor halaman (1-indexed).
  final int? page;

  /// Jumlah item per halaman.
  final int? limit;

  Map<String, Object?> toQueryParameters() => {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      };
}

// ignore_for_file: prefer_const_constructors, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/features/budget/models/models.dart';

/// FLT-303: Unit tests untuk BudgetPeriod dan request DTOs.
///
/// Checklist:
/// - [x] BudgetPeriod.fromJson parsing normal
/// - [x] BudgetPeriod.isActive — aktif ketika end_date >= hari ini
/// - [x] BudgetPeriod.isActive — selesai ketika end_date < hari ini
/// - [x] BudgetPeriod.statusLabel — 'Aktif' / 'Selesai'
/// - [x] BudgetPeriod.isDefault = true / false
/// - [x] excluded_weekdays parsing dari List
/// - [x] null-safe: categoryId / categoryName / categoryType nullable
/// - [x] Equatable: dua BudgetPeriod sama = equal
/// - [x] UpdateBudgetPeriodRequest.toJson — hanya include field non-null
/// - [x] CreateBudgetPeriodRequest.toJson — semua field required
/// - [x] BudgetPeriodListQuery.toQueryParameters — hanya non-null
/// - [x] BudgetPeriodListResponse.fromJson — parse list + meta null
void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final yesterday = today.subtract(const Duration(days: 1));
  final yesterdayStr =
      '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

  final tomorrow = today.add(const Duration(days: 1));
  final tomorrowStr =
      '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _baseJson({
    String? endDate,
    bool isDefault = false,
    int? categoryId,
    String? categoryName,
    String? categoryType,
  }) {
    return {
      'id': 1,
      'user_id': 42,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_type': categoryType,
      'name': 'Juni 2025',
      'total_budget': 3000000.0,
      'daily_budget_base': 150000.0,
      'start_date': '2025-06-01',
      'end_date': endDate ?? '2025-06-30',
      'working_days_count': 20,
      'excluded_weekdays': [0, 6],
      'budget_system': 'carry_over',
      'is_default': isDefault,
      'created_at': '2025-05-31T10:00:00.000Z',
    };
  }

  // ---------------------------------------------------------------------------
  // BudgetPeriod.fromJson
  // ---------------------------------------------------------------------------

  group('BudgetPeriod.fromJson — parsing', () {
    test('parsing field-field utama dari JSON backend', () {
      final bp = BudgetPeriod.fromJson(_baseJson());

      expect(bp.id, 1);
      expect(bp.userId, 42);
      expect(bp.name, 'Juni 2025');
      expect(bp.totalBudget, 3000000.0);
      expect(bp.dailyBudgetBase, 150000.0);
      expect(bp.startDate, '2025-06-01');
      expect(bp.endDate, '2025-06-30');
      expect(bp.workingDaysCount, 20);
      expect(bp.excludedWeekdays, [0, 6]);
      expect(bp.budgetSystem, 'carry_over');
      expect(bp.isDefault, false);
      expect(bp.createdAt, '2025-05-31T10:00:00.000Z');
    });

    test('is_default = true diparsing dengan benar', () {
      final bp = BudgetPeriod.fromJson(_baseJson(isDefault: true));
      expect(bp.isDefault, true);
    });

    test('category fields nullable — null ketika tidak ada', () {
      final bp = BudgetPeriod.fromJson(_baseJson());
      expect(bp.categoryId, isNull);
      expect(bp.categoryName, isNull);
      expect(bp.categoryType, isNull);
    });

    test('category fields nullable — terisi ketika ada', () {
      final bp = BudgetPeriod.fromJson(_baseJson(
        categoryId: 3,
        categoryName: 'Makanan',
        categoryType: 'expense',
      ));
      expect(bp.categoryId, 3);
      expect(bp.categoryName, 'Makanan');
      expect(bp.categoryType, 'expense');
    });

    test('total_budget dari int (bukan double) diparsing benar', () {
      final json = _baseJson();
      json['total_budget'] = 3000000; // int
      final bp = BudgetPeriod.fromJson(json);
      expect(bp.totalBudget, 3000000.0);
    });

    test('excluded_weekdays dari List kosong menghasilkan list kosong', () {
      final json = _baseJson();
      json['excluded_weekdays'] = <dynamic>[];
      final bp = BudgetPeriod.fromJson(json);
      expect(bp.excludedWeekdays, isEmpty);
    });

    test('excluded_weekdays null menghasilkan list kosong', () {
      final json = _baseJson();
      json['excluded_weekdays'] = null;
      final bp = BudgetPeriod.fromJson(json);
      expect(bp.excludedWeekdays, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetPeriod.isActive & statusLabel
  // ---------------------------------------------------------------------------

  group('BudgetPeriod.isActive — computed property', () {
    test('isActive = true ketika end_date = hari ini', () {
      final bp = BudgetPeriod.fromJson(_baseJson(endDate: todayStr));
      expect(bp.isActive, true);
      expect(bp.statusLabel, 'Aktif');
    });

    test('isActive = true ketika end_date = besok', () {
      final bp = BudgetPeriod.fromJson(_baseJson(endDate: tomorrowStr));
      expect(bp.isActive, true);
    });

    test('isActive = false ketika end_date = kemarin', () {
      final bp = BudgetPeriod.fromJson(_baseJson(endDate: yesterdayStr));
      expect(bp.isActive, false);
      expect(bp.statusLabel, 'Selesai');
    });

    test('isActive = false untuk masa lalu jauh', () {
      final bp = BudgetPeriod.fromJson(_baseJson(endDate: '2020-01-31'));
      expect(bp.isActive, false);
    });

    test('isActive = true untuk masa depan jauh', () {
      final bp = BudgetPeriod.fromJson(_baseJson(endDate: '2099-12-31'));
      expect(bp.isActive, true);
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetPeriod Equatable
  // ---------------------------------------------------------------------------

  group('BudgetPeriod Equatable', () {
    test('dua BudgetPeriod identik dianggap equal', () {
      final b1 = BudgetPeriod.fromJson(_baseJson(isDefault: true));
      final b2 = BudgetPeriod.fromJson(_baseJson(isDefault: true));
      expect(b1, equals(b2));
    });

    test('BudgetPeriod berbeda ID tidak equal', () {
      final json1 = _baseJson();
      final json2 = _baseJson();
      json2['id'] = 99;
      final b1 = BudgetPeriod.fromJson(json1);
      final b2 = BudgetPeriod.fromJson(json2);
      expect(b1, isNot(equals(b2)));
    });
  });

  // ---------------------------------------------------------------------------
  // UpdateBudgetPeriodRequest
  // ---------------------------------------------------------------------------

  group('UpdateBudgetPeriodRequest.toJson', () {
    test('hanya menyertakan field yang di-set (non-null)', () {
      const request = UpdateBudgetPeriodRequest(name: 'Juli 2025');
      final json = request.toJson();

      expect(json.containsKey('name'), true);
      expect(json['name'], 'Juli 2025');
      expect(json.containsKey('total_budget'), false);
      expect(json.containsKey('start_date'), false);
    });

    test('menyertakan semua field jika semua di-set', () {
      const request = UpdateBudgetPeriodRequest(
        name: 'Juli',
        totalBudget: 5000000,
        startDate: '2025-07-01',
        endDate: '2025-07-31',
        budgetSystem: 'invest',
        isDefault: true,
      );
      final json = request.toJson();

      expect(json['name'], 'Juli');
      expect(json['total_budget'], 5000000);
      expect(json['start_date'], '2025-07-01');
      expect(json['end_date'], '2025-07-31');
      expect(json['budget_system'], 'invest');
      expect(json['is_default'], true);
    });

    test('toJson kosong jika tidak ada field yang di-set', () {
      const request = UpdateBudgetPeriodRequest();
      expect(request.toJson(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // CreateBudgetPeriodRequest
  // ---------------------------------------------------------------------------

  group('CreateBudgetPeriodRequest.toJson', () {
    test('field required wajib ada di JSON', () {
      const request = CreateBudgetPeriodRequest(
        name: 'Agustus 2025',
        totalBudget: 3000000,
        startDate: '2025-08-01',
        endDate: '2025-08-31',
      );
      final json = request.toJson();

      expect(json['name'], 'Agustus 2025');
      expect(json['total_budget'], 3000000);
      expect(json['start_date'], '2025-08-01');
      expect(json['end_date'], '2025-08-31');
      expect(json['excluded_weekdays'], [0, 6]); // default
      expect(json['budget_system'], 'nothing'); // default
      expect(json['is_default'], false); // default
    });

    test('category_id tidak ada di JSON jika null', () {
      const request = CreateBudgetPeriodRequest(
        name: 'Test',
        totalBudget: 1000000,
        startDate: '2025-08-01',
        endDate: '2025-08-31',
      );
      expect(request.toJson().containsKey('category_id'), false);
    });

    test('category_id ada di JSON jika di-set', () {
      const request = CreateBudgetPeriodRequest(
        name: 'Test',
        totalBudget: 1000000,
        startDate: '2025-08-01',
        endDate: '2025-08-31',
        categoryId: 5,
      );
      expect(request.toJson()['category_id'], 5);
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetPeriodListQuery
  // ---------------------------------------------------------------------------

  group('BudgetPeriodListQuery.toQueryParameters', () {
    test('kosong jika tidak ada parameter', () {
      const q = BudgetPeriodListQuery();
      expect(q.toQueryParameters(), isEmpty);
    });

    test('menyertakan page dan limit jika di-set', () {
      const q = BudgetPeriodListQuery(page: 2, limit: 10);
      final params = q.toQueryParameters();
      expect(params['page'], 2);
      expect(params['limit'], 10);
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetPeriodListResponse.fromJson
  // ---------------------------------------------------------------------------

  group('BudgetPeriodListResponse.fromJson', () {
    test('parse list data tanpa meta (non-paginated)', () {
      final json = {
        'data': [_baseJson(), _baseJson()..['id'] = 2],
      };
      final response = BudgetPeriodListResponse.fromJson(json);

      expect(response.data.length, 2);
      expect(response.meta, isNull);
    });

    test('data kosong menghasilkan list kosong', () {
      final response = BudgetPeriodListResponse.fromJson({'data': <dynamic>[]});
      expect(response.data, isEmpty);
    });

    test('data null menghasilkan list kosong', () {
      final response = BudgetPeriodListResponse.fromJson({});
      expect(response.data, isEmpty);
    });

    test('meta di-parse jika ada', () {
      final json = {
        'data': <dynamic>[],
        'meta': {'page': 1, 'limit': 10, 'total': 0, 'total_pages': 0},
      };
      final response = BudgetPeriodListResponse.fromJson(json);
      expect(response.meta, isNotNull);
      expect(response.meta!.page, 1);
      expect(response.meta!.total, 0);
    });
  });
}

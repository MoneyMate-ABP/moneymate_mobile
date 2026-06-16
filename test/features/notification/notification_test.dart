import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate_mobile/core/network/api_client.dart';
import 'package:moneymate_mobile/features/notification/models/notification_history.dart';
import 'package:moneymate_mobile/features/notification/repositories/notification_repository.dart';

void main() {
  group('NotificationHistory.fromJson', () {
    test('should parse correctly from valid JSON', () {
      final json = {
        'id': 1,
        'title': 'Roll-over Budget',
        'body': 'Budget sisa Rp 50.000 dialihkan.',
        'budget_period_name': 'Juni 2025',
        'effective_budget': 150000.0,
        'carry_over': 50000.0,
        'is_read': false,
        'sent_at': '2025-06-16T17:00:00.000Z',
      };

      final notification = NotificationHistory.fromJson(json);

      expect(notification.id, 1);
      expect(notification.title, 'Roll-over Budget');
      expect(notification.body, 'Budget sisa Rp 50.000 dialihkan.');
      expect(notification.budgetPeriodName, 'Juni 2025');
      expect(notification.effectiveBudget, 150000.0);
      expect(notification.carryOver, 50000.0);
      expect(notification.isRead, false);
      expect(notification.sentAt, '2025-06-16T17:00:00.000Z');
    });

    test('should parse with default values when fields are missing or null', () {
      final json = {
        'id': 2,
        'effective_budget': 100000,
        'carry_over': null,
      };

      final notification = NotificationHistory.fromJson(json);

      expect(notification.id, 2);
      expect(notification.title, '');
      expect(notification.body, '');
      expect(notification.budgetPeriodName, isNull);
      expect(notification.effectiveBudget, 100000.0);
      expect(notification.carryOver, 0.0);
      expect(notification.isRead, false);
      expect(notification.sentAt, '');
    });
  });

  group('NotificationHistoryResponse.fromJson', () {
    test('should parse notification list and unread count', () {
      final json = {
        'data': [
          {
            'id': 1,
            'title': 'Notif 1',
            'body': 'Body 1',
            'effective_budget': 10000,
            'carry_over': 0,
            'is_read': true,
            'sent_at': '2025-06-16',
          },
          {
            'id': 2,
            'title': 'Notif 2',
            'body': 'Body 2',
            'effective_budget': 20000,
            'carry_over': 5000,
            'is_read': false,
            'sent_at': '2025-06-17',
          }
        ],
        'unread_count': 1,
      };

      final response = NotificationHistoryResponse.fromJson(json);

      expect(response.unreadCount, 1);
      expect(response.data.length, 2);
      expect(response.data[0].id, 1);
      expect(response.data[0].isRead, true);
      expect(response.data[1].id, 2);
      expect(response.data[1].isRead, false);
    });

    test('should handle empty or null fields gracefully', () {
      final response = NotificationHistoryResponse.fromJson({});
      expect(response.data, isEmpty);
      expect(response.unreadCount, 0);
    });
  });

  group('NotificationRepository', () {
    test('getHistory returns parsed data successfully', () async {
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test'),
        tokenProvider: () async => 'token',
        transport: (request) async {
          expect(request.method, 'GET');
          expect(request.uri.path, '/api/notifications/history');
          return const ApiResponse(
            statusCode: 200,
            body: {
              'data': [
                {'id': 1, 'effective_budget': 10000, 'carry_over': 0}
              ],
              'unread_count': 0
            },
          );
        },
      );

      final repo = NotificationRepository(client);
      final response = await repo.getHistory();

      expect(response.unreadCount, 0);
      expect(response.data.length, 1);
      expect(response.data[0].id, 1);
    });

    test('markRead triggers PATCH request', () async {
      var requestCalled = false;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test'),
        tokenProvider: () async => 'token',
        transport: (request) async {
          expect(request.method, 'PATCH');
          expect(request.uri.path, '/api/notifications/history/12/read');
          requestCalled = true;
          return const ApiResponse(statusCode: 200, body: {'ok': true});
        },
      );

      final repo = NotificationRepository(client);
      await repo.markRead(12);

      expect(requestCalled, isTrue);
    });

    test('markAllRead triggers PATCH request', () async {
      var requestCalled = false;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test'),
        tokenProvider: () async => 'token',
        transport: (request) async {
          expect(request.method, 'PATCH');
          expect(request.uri.path, '/api/notifications/history/read-all');
          requestCalled = true;
          return const ApiResponse(statusCode: 200, body: {'ok': true});
        },
      );

      final repo = NotificationRepository(client);
      await repo.markAllRead();

      expect(requestCalled, isTrue);
    });
  });
}

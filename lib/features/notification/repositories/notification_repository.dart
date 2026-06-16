import '../../../core/network/api_client.dart';
import '../models/notification_history.dart';

class NotificationRepository {
  const NotificationRepository(this._apiClient);
  final ApiClient _apiClient;

  static const _basePath = '/api/notifications/history';

  Future<NotificationHistoryResponse> getHistory() async {
    final response = await _apiClient.get(_basePath);
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'NotificationRepository: unexpected response shape from GET /api/notifications/history.',
      );
    }
    return NotificationHistoryResponse.fromJson(body);
  }

  Future<void> markRead(int id) async {
    await _apiClient.request('PATCH', '$_basePath/$id/read');
  }

  Future<void> markAllRead() async {
    await _apiClient.request('PATCH', '$_basePath/read-all');
  }
}

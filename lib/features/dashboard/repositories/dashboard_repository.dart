import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/dashboard_data.dart';

/// Repository responsible for fetching dashboard data from the backend.
///
/// Endpoint: `GET /api/dashboard`
/// Authentication: Bearer token (injected automatically by [ApiClient]).
///
/// The repository translates raw API responses into [DashboardData] and
/// re-throws structured [ApiException]s so that callers (Riverpod providers,
/// controllers) can react to errors uniformly.
class DashboardRepository {
  const DashboardRepository(this._apiClient);

  static const _path = '/api/dashboard';

  final ApiClient _apiClient;

  /// Fetches the current user's dashboard summary.
  ///
  /// Returns a [DashboardData] containing:
  /// - [DashboardData.totals] — all-time balance, income, and expense.
  /// - [DashboardData.budgets] — active budget count, today's effective /
  ///   spent / remaining totals, and per-period daily statuses.
  ///
  /// Throws [ApiException] on HTTP errors (e.g. 401, 500).
  /// Throws [FormatException] if the response body cannot be parsed.
  Future<DashboardData> fetchDashboard() async {
    final response = await _apiClient.get(_path);

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'DashboardRepository: unexpected response body type from GET /api/dashboard.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'DashboardRepository: missing or invalid "data" key in GET /api/dashboard response.',
      );
    }

    return DashboardData.fromJson(rawData);
  }
}

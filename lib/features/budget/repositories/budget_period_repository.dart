import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/models.dart';

/// Repository untuk keluarga `GET|PUT|DELETE|POST /api/budget-periods`.
///
/// Authentication: Bearer token (diinjeksi otomatis oleh [ApiClient]).
///
/// Menerjemahkan respons API mentah menjadi typed DTOs dan meneruskan
/// [ApiException] dari [ApiClient] ke caller (Riverpod providers, controllers)
/// agar dapat bereaksi secara seragam.
class BudgetPeriodRepository {
  const BudgetPeriodRepository(this._apiClient);

  static const _basePath = '/api/budget-periods';

  final ApiClient _apiClient;

  // ---------------------------------------------------------------------------
  // GET /api/budget-periods
  // ---------------------------------------------------------------------------

  /// Mengambil semua budget period milik user.
  ///
  /// Gunakan [query] untuk paginasi. Tanpa query, semua data dikembalikan
  /// tanpa pagination metadata.
  ///
  /// Mengembalikan [BudgetPeriodListResponse] yang berisi:
  /// - [BudgetPeriodListResponse.data]  — list [BudgetPeriod].
  /// - [BudgetPeriodListResponse.meta]  — pagination info (`null` jika tidak dipaginasi).
  ///
  /// Melempar [ApiException] untuk HTTP error.
  /// Melempar [FormatException] jika body tidak dapat di-parse.
  Future<BudgetPeriodListResponse> listBudgetPeriods([
    BudgetPeriodListQuery? query,
  ]) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: query?.toQueryParameters() ?? const {},
    );

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: unexpected response body from GET /api/budget-periods.',
      );
    }

    return BudgetPeriodListResponse.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // PUT /api/budget-periods/:id
  // ---------------------------------------------------------------------------

  /// Memperbarui budget period dengan [id].
  ///
  /// Minimal satu field dalam [request] harus non-null (divalidasi di backend).
  ///
  /// Mengembalikan [BudgetPeriod] yang sudah diperbarui.
  ///
  /// Melempar [ApiException] dengan `statusCode == 404` jika tidak ditemukan.
  Future<BudgetPeriod> updateBudgetPeriod(
    int id,
    UpdateBudgetPeriodRequest request,
  ) async {
    final response = await _apiClient.put(
      '$_basePath/$id',
      body: request.toJson(),
    );

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: unexpected response body from PUT /api/budget-periods/:id.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: missing "data" key in PUT /api/budget-periods/:id response.',
      );
    }

    return BudgetPeriod.fromJson(rawData);
  }

  // ---------------------------------------------------------------------------
  // DELETE /api/budget-periods/:id
  // ---------------------------------------------------------------------------

  /// Menghapus budget period dengan [id].
  ///
  /// Jika budget yang dihapus adalah default, backend akan otomatis
  /// memindahkan status default ke budget period terbaru lainnya.
  ///
  /// Melempar [ApiException] dengan `statusCode == 404` jika tidak ditemukan.
  /// Melempar [ApiException] dengan `statusCode == 400` jika ini satu-satunya
  /// budget period (tidak dapat dihapus).
  Future<void> deleteBudgetPeriod(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }

  // ---------------------------------------------------------------------------
  // POST /api/budget-periods/:id/set-default
  // ---------------------------------------------------------------------------

  /// Menetapkan budget period dengan [id] sebagai default.
  ///
  /// Backend akan memindahkan flag `is_default` dari budget lama ke budget ini.
  ///
  /// Mengembalikan [BudgetPeriod] yang sudah diperbarui.
  ///
  /// Melempar [ApiException] dengan `statusCode == 404` jika tidak ditemukan.
  Future<BudgetPeriod> setDefaultBudgetPeriod(int id) async {
    final response = await _apiClient.post('$_basePath/$id/set-default');

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: unexpected response body from POST /api/budget-periods/:id/set-default.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: missing "data" key in POST /api/budget-periods/:id/set-default response.',
      );
    }

    return BudgetPeriod.fromJson(rawData);
  }

  // ---------------------------------------------------------------------------
  // POST /api/budget-periods  (disiapkan untuk sprint berikutnya)
  // ---------------------------------------------------------------------------

  /// Membuat budget period baru.
  ///
  /// Mengembalikan [BudgetPeriod] yang baru dibuat.
  ///
  /// Melempar [ApiException] dengan `statusCode == 409` jika duplikat.
  Future<BudgetPeriod> createBudgetPeriod(
    CreateBudgetPeriodRequest request,
  ) async {
    final response = await _apiClient.post(
      _basePath,
      body: request.toJson(),
    );

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: unexpected response body from POST /api/budget-periods.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'BudgetPeriodRepository: missing "data" key in POST /api/budget-periods response.',
      );
    }

    return BudgetPeriod.fromJson(rawData);
  }
}

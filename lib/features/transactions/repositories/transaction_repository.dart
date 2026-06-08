import '../../../core/network/api_client.dart';
import '../models/models.dart';

/// Repository for the `GET|POST|PUT|DELETE /api/transactions` family.
///
/// Authentication: Bearer token (injected automatically by [ApiClient]).
///
/// Translates raw API responses into typed DTOs and forwards [ApiException]s
/// from [ApiClient] to callers unchanged, so Riverpod providers and
/// controllers can react uniformly.
class TransactionRepository {
  const TransactionRepository(this._apiClient);

  static const _basePath = '/api/transactions';

  final ApiClient _apiClient;

  // ---------------------------------------------------------------------------
  // GET /api/transactions
  // ---------------------------------------------------------------------------

  /// Fetches the current user's transactions.
  ///
  /// Use [query] to filter by date / type / category or to paginate results.
  /// When no query is provided all transactions are returned without
  /// pagination metadata.
  ///
  /// Returns [TransactionListResponse] which contains:
  /// - [TransactionListResponse.data] — list of [Transaction] items.
  /// - [TransactionListResponse.meta] — pagination info (`null` if not paginated).
  ///
  /// Throws [ApiException] on HTTP errors.
  /// Throws [FormatException] if the response body cannot be parsed.
  Future<TransactionListResponse> listTransactions([
    TransactionListQuery? query,
  ]) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: query?.toQueryParameters() ?? const {},
    );

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: unexpected response body from GET /api/transactions.',
      );
    }

    return TransactionListResponse.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // GET /api/transactions/:id
  // ---------------------------------------------------------------------------

  /// Fetches a single transaction by [id].
  ///
  /// Throws [ApiException] with `statusCode == 404` when not found.
  Future<Transaction> getTransactionById(int id) async {
    final response = await _apiClient.get('$_basePath/$id');

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: unexpected response body from GET /api/transactions/:id.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: missing "data" key in GET /api/transactions/:id response.',
      );
    }

    return Transaction.fromJson(rawData);
  }

  // ---------------------------------------------------------------------------
  // POST /api/transactions
  // ---------------------------------------------------------------------------

  /// Creates a new transaction.
  ///
  /// Returns the created [Transaction] (the server echoes back the full row).
  ///
  /// Throws [ApiException] with `statusCode == 409` on duplicate detection.
  Future<Transaction> createTransaction(CreateTransactionRequest request) async {
    final response = await _apiClient.post(
      _basePath,
      body: request.toJson(),
    );

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: unexpected response body from POST /api/transactions.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: missing "data" key in POST /api/transactions response.',
      );
    }

    return Transaction.fromJson(rawData);
  }

  // ---------------------------------------------------------------------------
  // PUT /api/transactions/:id
  // ---------------------------------------------------------------------------

  /// Updates an existing transaction identified by [id].
  ///
  /// At least one field in [request] must be non-null (enforced server-side).
  ///
  /// Returns the updated [Transaction].
  ///
  /// Throws [ApiException] with `statusCode == 404` when not found.
  Future<Transaction> updateTransaction(
    int id,
    UpdateTransactionRequest request,
  ) async {
    final response = await _apiClient.request(
      'PUT',
      '$_basePath/$id',
      body: request.toJson(),
    );

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: unexpected response body from PUT /api/transactions/:id.',
      );
    }

    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'TransactionRepository: missing "data" key in PUT /api/transactions/:id response.',
      );
    }

    return Transaction.fromJson(rawData);
  }

  // ---------------------------------------------------------------------------
  // DELETE /api/transactions/:id
  // ---------------------------------------------------------------------------

  /// Deletes the transaction identified by [id].
  ///
  /// Throws [ApiException] with `statusCode == 404` when not found.
  Future<void> deleteTransaction(int id) async {
    await _apiClient.request('DELETE', '$_basePath/$id');
  }
}

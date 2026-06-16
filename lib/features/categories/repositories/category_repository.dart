import '../../../core/network/api_client.dart';
import '../models/category.dart';

class CategoryRepository {
  const CategoryRepository(this._apiClient);

  static const _basePath = '/api/categories';
  final ApiClient _apiClient;

  /// Fetches all categories for the current user.
  Future<List<Category>> listCategories() async {
    final response = await _apiClient.get(_basePath);
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: unexpected list response body.');
    }
    final rawData = body['data'];
    if (rawData is! List) {
      throw const FormatException('CategoryRepository: list data key is not a list.');
    }
    return rawData
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  /// Fetches a single category by ID.
  Future<Category> getCategoryById(int id) async {
    final response = await _apiClient.get('$_basePath/$id');
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: unexpected get response body.');
    }
    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: get data key is not an object.');
    }
    return Category.fromJson(rawData);
  }

  /// Creates a new category.
  Future<Category> createCategory(String name, CategoryType type) async {
    final response = await _apiClient.post(
      _basePath,
      body: {
        'name': name,
        'type': type.toJson(),
      },
    );
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: unexpected create response body.');
    }
    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: create data key is not an object.');
    }
    return Category.fromJson(rawData);
  }

  /// Updates an existing category.
  Future<Category> updateCategory(int id, String name, CategoryType type) async {
    final response = await _apiClient.put(
      '$_basePath/$id',
      body: {
        'name': name,
        'type': type.toJson(),
      },
    );
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: unexpected update response body.');
    }
    final rawData = body['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('CategoryRepository: update data key is not an object.');
    }
    return Category.fromJson(rawData);
  }

  /// Deletes a category.
  Future<void> deleteCategory(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'models/category.dart';
import 'repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.listCategories();
});

class CategoryMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  Future<void> createCategory(String name, CategoryType type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.createCategory(name, type);
      ref.invalidate(categoriesProvider);
    });
  }

  Future<void> updateCategory(int id, String name, CategoryType type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateCategory(id, name, type);
      ref.invalidate(categoriesProvider);
    });
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteCategory(id);
      ref.invalidate(categoriesProvider);
    });
  }
}

final categoryMutationProvider =
    AsyncNotifierProvider<CategoryMutationNotifier, void>(
  CategoryMutationNotifier.new,
);

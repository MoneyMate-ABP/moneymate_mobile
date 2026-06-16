import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../models/category.dart';
import '../providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'expense', 'income', 'both'

  void _showFormSheet([Category? category]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MoneyMateTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryFormSheet(category: category),
    );
  }

  void _confirmDelete(Category category) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MoneyMateTheme.surface,
        title: const Text('Hapus Kategori'),
        content: Text(
          'Yakin ingin menghapus kategori "${category.name}"?\n\nKategori yang sudah digunakan di transaksi tidak bisa dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MoneyMateTheme.danger,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(categoryMutationProvider.notifier);
              await notifier.deleteCategory(category.id);
              if (mounted) {
                final state = ref.read(categoryMutationProvider);
                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: ${state.error}'),
                      backgroundColor: MoneyMateTheme.danger,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori berhasil dihapus.'),
                      backgroundColor: MoneyMateTheme.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Kelola kategori pemasukan dan pengeluaran Anda.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari kategori...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 14),

              // Filters Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: _filterType == 'all',
                      onSelected: () => setState(() => _filterType = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pengeluaran',
                      selected: _filterType == 'expense',
                      onSelected: () => setState(() => _filterType = 'expense'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pemasukan',
                      selected: _filterType == 'income',
                      onSelected: () => setState(() => _filterType = 'income'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Keduanya',
                      selected: _filterType == 'both',
                      onSelected: () => setState(() => _filterType = 'both'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category List
              Expanded(
                child: categoriesState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Gagal memuat kategori: $err'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(categoriesProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                  data: (list) {
                    final filtered = list.where((c) {
                      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesType = _filterType == 'all' || c.type.name == _filterType;
                      return matchesSearch && matchesType;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isNotEmpty || _filterType != 'all'
                              ? 'Tidak ada kategori yang cocok.'
                              : 'Belum ada kategori.',
                          style: const TextStyle(color: MoneyMateTheme.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        return _CategoryItem(
                          category: cat,
                          onEdit: () => _showFormSheet(cat),
                          onDelete: () => _confirmDelete(cat),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = switch (category.type) {
      CategoryType.expense => ('💸', MoneyMateTheme.danger),
      CategoryType.income => ('💰', MoneyMateTheme.success),
      CategoryType.both => ('🔄', MoneyMateTheme.accent),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  category.type.label,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: MoneyMateTheme.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({this.category});

  final Category? category;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late CategoryType _selectedType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(categoryMutationProvider.notifier);
    
    if (widget.category != null) {
      await notifier.updateCategory(widget.category!.id, name, _selectedType);
    } else {
      await notifier.createCategory(name, _selectedType);
    }

    if (mounted) {
      setState(() => _saving = false);
      final state = ref.read(categoryMutationProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${state.error}'),
            backgroundColor: MoneyMateTheme.danger,
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category != null
                  ? 'Kategori berhasil diperbarui.'
                  : 'Kategori berhasil ditambahkan.',
            ),
            backgroundColor: MoneyMateTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEdit ? 'Edit Kategori' : 'Tambah Kategori',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Contoh: Makanan, Transportasi',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tipe Kategori',
            style: TextStyle(color: MoneyMateTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TypeSelectButton(
                  label: 'Pengeluaran',
                  emoji: '💸',
                  selected: _selectedType == CategoryType.expense,
                  color: MoneyMateTheme.danger,
                  onTap: () => setState(() => _selectedType = CategoryType.expense),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeSelectButton(
                  label: 'Pemasukan',
                  emoji: '💰',
                  selected: _selectedType == CategoryType.income,
                  color: MoneyMateTheme.success,
                  onTap: () => setState(() => _selectedType = CategoryType.income),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeSelectButton(
                  label: 'Keduanya',
                  emoji: '🔄',
                  selected: _selectedType == CategoryType.both,
                  color: MoneyMateTheme.accent,
                  onTap: () => setState(() => _selectedType = CategoryType.both),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kategori'),
          ),
        ],
      ),
    );
  }
}

class _TypeSelectButton extends StatelessWidget {
  const _TypeSelectButton({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: selected ? color : Colors.white10,
          width: selected ? 2 : 1,
        ),
        backgroundColor: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? color : MoneyMateTheme.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

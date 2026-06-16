import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../../categories/models/category.dart' as cat_model;
import '../../categories/providers.dart' as cat_prov;
import '../../dashboard/providers.dart';
import '../../transactions/models/models.dart';
import '../../transactions/providers.dart';
import '../models/receipt_scan_result.dart';
import '../providers/receipt_providers.dart';

class _MutationDraftItem {
  _MutationDraftItem({
    required this.selected,
    required this.type,
    required this.amountController,
    required this.noteController,
    required this.dateController,
    required this.suggestion,
    required this.merchant,
  });

  bool selected;
  TransactionType type;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TextEditingController dateController;
  int? categoryId;
  final String suggestion;
  final String merchant;
  bool categoryMatched = false;
}

class MutationReviewScreen extends ConsumerStatefulWidget {
  const MutationReviewScreen({required this.results, super.key});
  final List<ReceiptScanResult> results;

  @override
  ConsumerState<MutationReviewScreen> createState() => _MutationReviewScreenState();
}

class _MutationReviewScreenState extends ConsumerState<MutationReviewScreen> {
  final List<_MutationDraftItem> _drafts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final res in widget.results) {
      _drafts.add(
        _MutationDraftItem(
          selected: true,
          type: res.type == 'income' ? TransactionType.income : TransactionType.expense,
          amountController: TextEditingController(
            text: res.amount > 0 ? res.amount.toStringAsFixed(0) : '',
          ),
          noteController: TextEditingController(
            text: res.note ?? res.merchantName ?? '',
          ),
          dateController: TextEditingController(
            text: res.date ?? DateTime.now().toIso8601String().split('T')[0],
          ),
          suggestion: res.categorySuggestion ?? '',
          merchant: res.merchantName ?? '',
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.amountController.dispose();
      d.noteController.dispose();
      d.dateController.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(_MutationDraftItem item) async {
    final initialDate = DateTime.tryParse(item.dateController.text) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MoneyMateTheme.accent,
              onPrimary: Colors.black,
              surface: MoneyMateTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        item.dateController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveAll() async {
    final selectedDrafts = _drafts.where((d) => d.selected).toList();
    if (selectedDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih minimal satu transaksi untuk diimpor.')),
      );
      return;
    }

    // Validation
    for (final d in selectedDrafts) {
      final amount = double.tryParse(d.amountController.text.trim());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah nominal transaksi harus valid dan lebih dari 0.')),
        );
        return;
      }
      if (d.categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori untuk setiap transaksi wajib dipilih.')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    int savedCount = 0;
    int failedCount = 0;

    final repo = ref.read(transactionRepositoryProvider);

    for (final d in selectedDrafts) {
      try {
        final amountVal = double.parse(d.amountController.text.trim());
        final request = CreateTransactionRequest(
          categoryId: d.categoryId!,
          type: d.type,
          amount: amountVal,
          date: d.dateController.text.trim(),
          note: d.noteController.text.trim(),
        );
        await repo.createTransaction(request);
        savedCount++;
      } catch (_) {
        failedCount++;
      }
    }

    // Invalidate list & dashboard
    ref.invalidate(transactionsProvider);
    ref.invalidate(dashboardProvider);

    if (mounted) {
      setState(() => _saving = false);
      // Clear the mutation picked list since they are imported
      ref.read(mutationListProvider.notifier).clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount transaksi berhasil disimpan${failedCount > 0 ? ', $failedCount gagal' : ''}.'),
          backgroundColor: failedCount > 0 ? MoneyMateTheme.warning : MoneyMateTheme.success,
        ),
      );
      Navigator.of(context).pop(); // Go back
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(cat_prov.categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Mutasi Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all_rounded),
            tooltip: 'Pilih Semua',
            onPressed: () {
              setState(() {
                for (final d in _drafts) {
                  d.selected = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.deselect_rounded),
            tooltip: 'Batal Pilih Semua',
            onPressed: () {
              setState(() {
                for (final d in _drafts) {
                  d.selected = false;
                }
              });
            },
          ),
        ],
      ),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat kategori: $err')),
        data: (categoriesList) {
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _drafts.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final item = _drafts[index];

                        // Filter categories matching the type
                        final filteredCats = categoriesList.where((cat) {
                          if (item.type == TransactionType.expense) {
                            return cat.type == cat_model.CategoryType.expense ||
                                cat.type == cat_model.CategoryType.both;
                          } else {
                            return cat.type == cat_model.CategoryType.income ||
                                cat.type == cat_model.CategoryType.both;
                          }
                        }).toList();

                        // Try to auto-select suggested category once
                        if (!item.categoryMatched && item.categoryId == null) {
                          final suggestion = item.suggestion.toLowerCase().trim();
                          final merchant = item.merchant.toLowerCase().trim();
                          final noteText = item.noteController.text.toLowerCase().trim();

                          cat_model.Category? matched;
                          if (suggestion.isNotEmpty) {
                            matched = filteredCats.where((cat) =>
                              cat.name.toLowerCase().contains(suggestion) ||
                              suggestion.contains(cat.name.toLowerCase())
                            ).firstOrNull;
                          }
                          if (matched == null && merchant.isNotEmpty) {
                            matched = filteredCats.where((cat) =>
                              cat.name.toLowerCase().contains(merchant) ||
                              merchant.contains(cat.name.toLowerCase())
                            ).firstOrNull;
                          }
                          if (matched == null && noteText.isNotEmpty) {
                            matched = filteredCats.where((cat) =>
                              cat.name.toLowerCase().contains(noteText) ||
                              noteText.contains(cat.name.toLowerCase())
                            ).firstOrNull;
                          }

                          if (matched != null) {
                            item.categoryId = matched.id;
                          } else if (filteredCats.isNotEmpty) {
                            item.categoryId = filteredCats.first.id;
                          }
                          item.categoryMatched = true;
                        }

                        // Verify if currently selected ID belongs to filteredCats, else reset
                        if (item.categoryId != null &&
                            !filteredCats.any((cat) => cat.id == item.categoryId)) {
                          item.categoryId = null;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: item.selected
                                  ? MoneyMateTheme.accent.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      activeColor: MoneyMateTheme.accent,
                                      value: item.selected,
                                      onChanged: (val) {
                                        setState(() => item.selected = val ?? false);
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: item.noteController,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: 'Catatan / Merchant',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: item.amountController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: 'Nominal',
                                          prefixText: 'Rp ',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<TransactionType>(
                                        initialValue: item.type,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: 'Tipe',
                                        ),
                                        dropdownColor: MoneyMateTheme.surface,
                                        items: const [
                                          DropdownMenuItem(
                                            value: TransactionType.expense,
                                            child: Text('Keluar'),
                                          ),
                                          DropdownMenuItem(
                                            value: TransactionType.income,
                                            child: Text('Masuk'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              item.type = val;
                                              item.categoryMatched = false;
                                              item.categoryId = null; // trigger re-match
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        controller: item.dateController,
                                        readOnly: true,
                                        onTap: () => _selectDate(item),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: 'Tanggal',
                                          suffixIcon: Icon(Icons.calendar_today, size: 14),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<int>(
                                        initialValue: item.categoryId,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: 'Kategori',
                                        ),
                                        dropdownColor: MoneyMateTheme.surface,
                                        hint: const Text('Pilih Kategori'),
                                        items: filteredCats.map((cat) {
                                          return DropdownMenuItem<int>(
                                            value: cat.id,
                                            child: Text(cat.name),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() => item.categoryId = val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: MoneyMateTheme.surface,
                      border: Border(top: BorderSide(color: MoneyMateTheme.border)),
                    ),
                    child: ElevatedButton(
                      onPressed: _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MoneyMateTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text('Simpan Transaksi Terpilih (${_drafts.where((d) => d.selected).length})'),
                    ),
                  ),
                ],
              ),
              if (_saving)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: MoneyMateTheme.accent),
                        SizedBox(height: 16),
                        Text('Menyimpan semua transaksi...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

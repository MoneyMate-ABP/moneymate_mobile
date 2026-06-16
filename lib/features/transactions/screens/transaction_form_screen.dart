import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../categories/models/category.dart' as cat_model;
import '../../categories/providers.dart' as cat_prov;
import '../../dashboard/providers.dart';
import '../../receipt/models/receipt_scan_result.dart';
import '../models/models.dart';
import '../providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    this.transaction,
    this.scanResult,
    super.key,
  });

  final Transaction? transaction;
  final ReceiptScanResult? scanResult;

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;
  late TransactionType _selectedType;
  int? _selectedCategoryId;
  double? _latitude;
  double? _longitude;
  bool _saving = false;
  bool _categoryMatched = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    final scan = widget.scanResult;

    _amountController = TextEditingController(
      text: tx != null
          ? tx.amount.toStringAsFixed(0)
          : (scan != null && scan.amount > 0 ? scan.amount.toStringAsFixed(0) : ''),
    );
    _noteController = TextEditingController(
      text: tx?.note ?? scan?.note ?? scan?.merchantName ?? '',
    );
    _dateController = TextEditingController(
      text: tx?.date ?? scan?.date ?? DateTime.now().toIso8601String().split('T')[0],
    );
    _selectedType = tx?.type ??
        (scan?.type == 'income' ? TransactionType.income : TransactionType.expense);
    _selectedCategoryId = tx?.categoryId;
    _latitude = tx?.latitude;
    _longitude = tx?.longitude;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initialDate = DateTime.tryParse(_dateController.text) ?? DateTime.now();
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
        _dateController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  void _useMockLocation() {
    setState(() {
      // Mock coordinates near central Jakarta
      _latitude = -6.20000;
      _longitude = 106.81667;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi diatur ke DKI Jakarta (Mock)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori.')),
      );
      return;
    }

    final amountVal = double.tryParse(_amountController.text.trim());
    if (amountVal == null || amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus berupa angka positif.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      
      if (_isEdit) {
        final request = UpdateTransactionRequest(
          categoryId: _selectedCategoryId,
          type: _selectedType,
          amount: amountVal,
          date: _dateController.text.trim(),
          note: _noteController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        await repo.updateTransaction(widget.transaction!.id, request);
      } else {
        final request = CreateTransactionRequest(
          categoryId: _selectedCategoryId!,
          type: _selectedType,
          amount: amountVal,
          date: _dateController.text.trim(),
          note: _noteController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        await repo.createTransaction(request);
      }

      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardProvider); // dashboard total totals and balances
      if (_isEdit) {
        ref.invalidate(transactionByIdProvider(widget.transaction!.id));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Transaksi berhasil diperbarui.' : 'Transaksi berhasil ditambahkan.'),
            backgroundColor: MoneyMateTheme.success,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $err'),
            backgroundColor: MoneyMateTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(cat_prov.categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _selectedType == TransactionType.expense
                              ? MoneyMateTheme.danger
                              : Colors.white10,
                        ),
                        backgroundColor: _selectedType == TransactionType.expense
                            ? MoneyMateTheme.danger.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      onPressed: () => setState(() => _selectedType = TransactionType.expense),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💸 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'Pengeluaran',
                            style: TextStyle(
                              color: _selectedType == TransactionType.expense
                                  ? MoneyMateTheme.danger
                                  : MoneyMateTheme.textSecondary,
                              fontWeight: _selectedType == TransactionType.expense
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _selectedType == TransactionType.income
                              ? MoneyMateTheme.success
                              : Colors.white10,
                        ),
                        backgroundColor: _selectedType == TransactionType.income
                            ? MoneyMateTheme.success.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      onPressed: () => setState(() => _selectedType = TransactionType.income),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💵 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'Pemasukan',
                            style: TextStyle(
                              color: _selectedType == TransactionType.income
                                  ? MoneyMateTheme.success
                                  : MoneyMateTheme.textSecondary,
                              fontWeight: _selectedType == TransactionType.income
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount textfield
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Jumlah wajib diisi';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category dropdown
              categoriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text(
                  'Gagal memuat kategori: $err',
                  style: const TextStyle(color: MoneyMateTheme.danger),
                ),
                data: (list) {
                  // Filter categories based on transaction type:
                  // Expense: show 'expense' & 'both'
                  // Income: show 'income' & 'both'
                  final filteredCats = list.where((cat) {
                    if (_selectedType == TransactionType.expense) {
                      return cat.type == cat_model.CategoryType.expense || cat.type == cat_model.CategoryType.both;
                    } else {
                      return cat.type == cat_model.CategoryType.income || cat.type == cat_model.CategoryType.both;
                    }
                  }).toList();

                  // Match category suggestion if from scan result
                  if (!_categoryMatched && _selectedCategoryId == null && widget.scanResult != null) {
                    final suggestion = widget.scanResult!.categorySuggestion?.toLowerCase().trim() ?? '';
                    final merchant = widget.scanResult!.merchantName?.toLowerCase().trim() ?? '';
                    final note = widget.scanResult!.note?.toLowerCase().trim() ?? '';
                    
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
                    if (matched == null && note.isNotEmpty) {
                      matched = filteredCats.where((cat) =>
                        cat.name.toLowerCase().contains(note) ||
                        note.contains(cat.name.toLowerCase())
                      ).firstOrNull;
                    }
                    
                    if (matched != null) {
                      _selectedCategoryId = matched.id;
                    } else if (filteredCats.isNotEmpty) {
                      _selectedCategoryId = filteredCats.first.id;
                    }
                    _categoryMatched = true;
                  }

                  // If selected category ID is not in the filtered categories list, reset it
                  if (_selectedCategoryId != null &&
                      !filteredCats.any((cat) => cat.id == _selectedCategoryId)) {
                    _selectedCategoryId = null;
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
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
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Kategori wajib diisi' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Date picker field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Tanggal wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // Note field
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Catatan tambahan (opsional)',
                ),
              ),
              const SizedBox(height: 20),

              // Geolocation mock input
              Card(
                color: Colors.white.withValues(alpha: 0.02),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi (Opsional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (_latitude != null && _longitude != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 13, color: MoneyMateTheme.success),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, color: MoneyMateTheme.danger, size: 18),
                              onPressed: _clearLocation,
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'Belum ada data lokasi',
                          style: TextStyle(fontStyle: FontStyle.italic, color: MoneyMateTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _useMockLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Gunakan Lokasi Saat Ini (Mock)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

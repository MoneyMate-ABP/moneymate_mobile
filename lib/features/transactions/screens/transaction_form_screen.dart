import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/location/location_service.dart';
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
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late TransactionType _selectedType;
  int? _selectedCategoryId;
  double? _latitude;
  double? _longitude;
  bool _saving = false;
  bool _categoryMatched = false;
  bool _detectingLocation = false;

  String? _resolvedPlaceName;
  bool _loadingPlaceName = false;
  WebViewController? _mapController;

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

    _latController = TextEditingController(text: _latitude?.toString() ?? '');
    _lngController = TextEditingController(text: _longitude?.toString() ?? '');

    _latController.addListener(_onCoordinatesChanged);
    _lngController.addListener(_onCoordinatesChanged);

    if (_latitude != null && _longitude != null) {
      _updateMapPreview(_latitude!, _longitude!);
      _resolveLocationName(_latitude!, _longitude!);
    }
  }

  @override
  void dispose() {
    _latController.removeListener(_onCoordinatesChanged);
    _lngController.removeListener(_onCoordinatesChanged);
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _onCoordinatesChanged() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat != null && lng != null) {
      if (lat != _latitude || lng != _longitude) {
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });
        _updateMapPreview(lat, lng);
        _resolveLocationName(lat, lng);
      }
    } else {
      if (_latitude != null || _longitude != null) {
        setState(() {
          _latitude = null;
          _longitude = null;
          _resolvedPlaceName = null;
          _mapController = null;
        });
      }
    }
  }

  void _resolveLocationName(double lat, double lng) async {
    setState(() {
      _loadingPlaceName = true;
      _resolvedPlaceName = null;
    });
    try {
      final name = await LocationService.instance.getPlaceName(lat, lng);
      if (mounted) {
        setState(() {
          _resolvedPlaceName = name;
          _loadingPlaceName = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedPlaceName = 'Gagal memuat nama lokasi';
          _loadingPlaceName = false;
        });
      }
    }
  }

  void _updateMapPreview(double lat, double lng) {
    final url = 'https://maps.google.com/maps?q=$lat,$lng&z=15&output=embed';
    if (_mapController == null) {
      _mapController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadRequest(Uri.parse(url));
    } else {
      _mapController!.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil dideteksi.'),
            backgroundColor: MoneyMateTheme.success,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendeteksi lokasi: $err'),
            backgroundColor: MoneyMateTheme.danger,
            action: SnackBarAction(
              label: 'Gunakan Mock',
              textColor: Colors.white,
              onPressed: _useMockLocation,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _detectingLocation = false);
      }
    }
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
      _latController.text = '-6.20000';
      _lngController.text = '106.81667';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi diatur ke DKI Jakarta (Mock)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLocation() {
    _latController.clear();
    _lngController.clear();
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

              // Geolocation input
              Card(
                color: Colors.white.withValues(alpha: 0.02),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Lokasi (Opsional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _detectingLocation ? null : _detectLocation,
                              icon: _detectingLocation
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    )
                                  : const Icon(Icons.my_location, size: 16),
                              label: Text(_detectingLocation ? 'Mendeteksi...' : 'Deteksi Lokasi Saya'),
                            ),
                          ),
                          if (_latitude != null && _longitude != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: MoneyMateTheme.danger),
                              onPressed: _clearLocation,
                              tooltip: 'Hapus Lokasi',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: '-6.20000',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: '106.81667',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 12),
                        // Geocoded Place Name
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_drop, color: MoneyMateTheme.accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _loadingPlaceName
                                    ? const Text(
                                        'Mencari nama lokasi...',
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                      )
                                    : Text(
                                        _resolvedPlaceName ?? 'Nama lokasi tidak tersedia',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        if (_mapController != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 160,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: WebViewWidget(controller: _mapController!),
                          ),
                        ],
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

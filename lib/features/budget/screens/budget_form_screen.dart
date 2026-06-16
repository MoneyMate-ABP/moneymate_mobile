import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../categories/providers.dart' as cat_prov;
import '../../dashboard/providers.dart';
import '../models/models.dart';
import '../providers.dart';


class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({this.budget, super.key});

  final BudgetPeriod? budget;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _totalBudgetController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  
  int? _selectedCategoryId;
  late String _budgetSystem;
  late List<int> _excludedWeekdays;
  bool _saving = false;

  bool get _isEdit => widget.budget != null;

  static const _weekdays = [
    (value: 0, label: 'Minggu'),
    (value: 1, label: 'Senin'),
    (value: 2, label: 'Selasa'),
    (value: 3, label: 'Rabu'),
    (value: 4, label: 'Kamis'),
    (value: 5, label: 'Jumat'),
    (value: 6, label: 'Sabtu'),
  ];

  static const _budgetSystemOptions = [
    (value: 'nothing', label: 'Standar', desc: 'Setiap hari dimulai dari budget yang sama, tanpa membawa sisa atau minus.'),
    (value: 'carry_over', label: 'Bawa Sisa', desc: 'Sisa atau minus hari ini akan ditambahkan ke budget besok.'),
    (value: 'invest', label: 'Tabungan', desc: 'Sisa positif hari ini disimpan sebagai tabungan, tidak dibawa ke besok.'),
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _nameController = TextEditingController(text: b?.name ?? '');
    _totalBudgetController = TextEditingController(
      text: b != null ? b.totalBudget.toStringAsFixed(0) : '',
    );
    _startDateController = TextEditingController(
      text: b?.startDate ?? _dateOnlyStr(DateTime.now().subtract(Duration(days: DateTime.now().day - 1))),
    );
    _endDateController = TextEditingController(
      text: b?.endDate ?? _dateOnlyStr(DateTime(DateTime.now().year, DateTime.now().month + 1, 0)),
    );
    _selectedCategoryId = b?.categoryId;
    _budgetSystem = b?.budgetSystem ?? 'nothing';
    _excludedWeekdays = b?.excludedWeekdays ?? [0, 6];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalBudgetController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _dateOnlyStr(DateTime dt) => dt.toIso8601String().split('T')[0];

  Future<void> _selectDate(TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
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

    if (picked != null) {
      setState(() {
        controller.text = _dateOnlyStr(picked);
      });
    }
  }

  // Live Calculations Preview
  Map<String, dynamic> _calculatePreview() {
    final start = DateTime.tryParse(_startDateController.text);
    final end = DateTime.tryParse(_endDateController.text);
    final total = double.tryParse(_totalBudgetController.text.trim()) ?? 0;

    if (start == null || end == null || end.isBefore(start)) {
      return {'total': 0, 'working': 0, 'weekend': 0, 'daily': 0.0};
    }

    final totalDays = end.difference(start).inDays + 1;
    int workingDays = 0;
    
    for (int i = 0; i < totalDays; i++) {
      final curDay = start.add(Duration(days: i));
      if (!_excludedWeekdays.contains(curDay.weekday % 7)) {
        workingDays++;
      }
    }

    final weekendDays = totalDays - workingDays;
    final dailyBudget = workingDays > 0 ? total / workingDays : 0.0;

    return {
      'total': totalDays,
      'working': workingDays,
      'weekend': weekendDays,
      'daily': dailyBudget,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final start = DateTime.tryParse(_startDateController.text);
    final end = DateTime.tryParse(_endDateController.text);
    if (start == null || end == null || end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal Selesai tidak boleh mendahului Tanggal Mulai.')),
      );
      return;
    }

    final totalVal = double.tryParse(_totalBudgetController.text.trim());
    if (totalVal == null || totalVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total Budget harus berupa angka positif.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(budgetPeriodRepositoryProvider);

      if (_isEdit) {
        final request = UpdateBudgetPeriodRequest(
          name: _nameController.text.trim(),
          totalBudget: totalVal,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          categoryId: _selectedCategoryId,
          budgetSystem: _budgetSystem,
          excludedWeekdays: _excludedWeekdays,
        );
        await repo.updateBudgetPeriod(widget.budget!.id, request);
      } else {
        final request = CreateBudgetPeriodRequest(
          name: _nameController.text.trim(),
          totalBudget: totalVal,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          categoryId: _selectedCategoryId,
          budgetSystem: _budgetSystem,
          excludedWeekdays: _excludedWeekdays,
        );
        await repo.createBudgetPeriod(request);
      }

      ref.invalidate(budgetPeriodsProvider);
      ref.invalidate(dashboardProvider); // refresh dashboard values if new default or dates active

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Budget berhasil diperbarui.' : 'Budget berhasil dibuat.'),
            backgroundColor: MoneyMateTheme.success,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan budget: $err'),
            backgroundColor: MoneyMateTheme.danger,
          ),
        );
      }
    }
  }

  void _showSystemInfo() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MoneyMateTheme.surface,
        title: const Text('Tentang Sistem Anggaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _budgetSystemOptions
                .map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: MoneyMateTheme.accent),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt.desc,
                            style: const TextStyle(fontSize: 12, color: MoneyMateTheme.textSecondary),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(cat_prov.categoriesProvider);
    final preview = _calculatePreview();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Anggaran' : 'Buat Anggaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Budget',
                  hintText: 'Contoh: Budget April 2026',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama budget wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _totalBudgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Budget (Rp)',
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Total budget wajib diisi';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Total budget harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () => _selectDate(_startDateController),
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Mulai',
                        suffixIcon: Icon(Icons.calendar_today, size: 16),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () => _selectDate(_endDateController),
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Selesai',
                        suffixIcon: Icon(Icons.calendar_today, size: 16),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              categoriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text(
                  'Gagal memuat kategori: $err',
                  style: const TextStyle(color: MoneyMateTheme.danger),
                ),
                data: (list) => DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  dropdownColor: MoneyMateTheme.surface,
                  decoration: const InputDecoration(labelText: 'Kategori (Opsional)'),
                  hint: const Text('Global (Semua Kategori)'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Global (Semua kategori)'),
                    ),
                    ...list.map((cat) => DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sistem Anggaran'),
                  TextButton(
                    onPressed: _showSystemInfo,
                    child: const Text('Pelajari Sistem'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _budgetSystem,
                dropdownColor: MoneyMateTheme.surface,
                decoration: const InputDecoration(labelText: 'Sistem'),
                items: _budgetSystemOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt.value,
                          child: Text(opt.label),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _budgetSystem = val ?? _budgetSystem),
              ),
              const SizedBox(height: 20),

              const Text(
                'Hari yang Tidak Dihitung',
                style: TextStyle(color: MoneyMateTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekdays.map((day) {
                  final isExcluded = _excludedWeekdays.contains(day.value);
                  return FilterChip(
                    label: Text(day.label),
                    selected: isExcluded,
                    selectedColor: MoneyMateTheme.accent.withValues(alpha: 0.2),
                    checkmarkColor: MoneyMateTheme.accent,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _excludedWeekdays = [..._excludedWeekdays, day.value];
                        } else {
                          _excludedWeekdays = _excludedWeekdays.where((v) => v != day.value).toList();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Live Preview Card
              Card(
                color: Colors.white.withValues(alpha: 0.02),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: MoneyMateTheme.accent),
                          SizedBox(width: 8),
                          Text(
                            'Live Preview',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PreviewStat(value: '${preview['total']}', label: 'Total Hari'),
                          _PreviewStat(value: '${preview['working']}', label: 'Hari Dihitung'),
                          _PreviewStat(value: '${preview['weekend']}', label: 'Hari Dilewati'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimasi Budget Harian'),
                          Text(
                            Formatter.formatRupiah(preview['daily']),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MoneyMateTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Buat Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: MoneyMateTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

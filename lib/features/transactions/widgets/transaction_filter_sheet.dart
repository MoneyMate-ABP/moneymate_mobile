import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/models.dart';
import '../screens/transaction_list_screen.dart';

/// A draggable bottom sheet that lets the user configure filters for the
/// transaction list (date range, type, category/search).
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => const TransactionFilterSheet(),
/// );
/// ```
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  // Local copies mutated by the form; applied to global state on "Terapkan".
  late TransactionFilter _draft;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(transactionFilterProvider);
    _searchController.text = _draft.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _draft.endDate ?? DateTime(2100),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(startDate: picked));
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.endDate ?? DateTime.now(),
      firstDate: _draft.startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(endDate: picked));
    }
  }

  void _apply() {
    // Flush the search text field into the draft.
    final q = _searchController.text.trim();
    final finalDraft = _draft.copyWith(
      searchQuery: q.isEmpty ? null : q,
    );
    ref.read(transactionFilterProvider.notifier).state = finalDraft;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _draft = const TransactionFilter();
      _searchController.clear();
    });
    ref.read(transactionFilterProvider.notifier).state =
        const TransactionFilter();
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: MoneyMateTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, mq.viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title row ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transaksi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: _reset,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: MoneyMateTheme.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search ──────────────────────────────────────────────────────
          _SectionLabel(label: 'Cari'),
          const SizedBox(height: 8),
          _SearchField(controller: _searchController),
          const SizedBox(height: 20),

          // ── Type ────────────────────────────────────────────────────────
          _SectionLabel(label: 'Tipe'),
          const SizedBox(height: 8),
          _TypeSelector(
            selected: _draft.type,
            onChanged: (t) => setState(() => _draft = _draft.copyWith(type: t)),
          ),
          const SizedBox(height: 20),

          // ── Date Range ──────────────────────────────────────────────────
          _SectionLabel(label: 'Rentang Tanggal'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DatePickerButton(
                  label: _draft.startDate != null
                      ? _formatDate(_draft.startDate!)
                      : 'Mulai',
                  icon: Icons.calendar_today_rounded,
                  onTap: _pickStartDate,
                  hasValue: _draft.startDate != null,
                  onClear: _draft.startDate != null
                      ? () => setState(
                            () => _draft = _draft.copyWith(startDate: null),
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: MoneyMateTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DatePickerButton(
                  label: _draft.endDate != null
                      ? _formatDate(_draft.endDate!)
                      : 'Selesai',
                  icon: Icons.calendar_month_rounded,
                  onTap: _pickEndDate,
                  hasValue: _draft.endDate != null,
                  onClear: _draft.endDate != null
                      ? () => setState(
                            () => _draft = _draft.copyWith(endDate: null),
                          )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Apply button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: MoneyMateTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Terapkan Filter',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: MoneyMateTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: MoneyMateTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Cari kategori, catatan, jumlah…',
          hintStyle: const TextStyle(
            color: MoneyMateTheme.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: MoneyMateTheme.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

/// Three-chip selector for transaction type (All / Income / Expense).
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          label: 'Semua',
          icon: Icons.swap_vert_rounded,
          color: MoneyMateTheme.accent,
          isSelected: selected == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: 'Pemasukan',
          icon: Icons.arrow_downward_rounded,
          color: MoneyMateTheme.success,
          isSelected: selected == TransactionType.income,
          onTap: () => onChanged(TransactionType.income),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: 'Pengeluaran',
          icon: Icons.arrow_upward_rounded,
          color: MoneyMateTheme.danger,
          isSelected: selected == TransactionType.expense,
          onTap: () => onChanged(TransactionType.expense),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? color : MoneyMateTheme.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? color : MoneyMateTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.hasValue,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasValue;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final color =
        hasValue ? MoneyMateTheme.accent : MoneyMateTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? MoneyMateTheme.accent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? MoneyMateTheme.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      hasValue ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: MoneyMateTheme.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

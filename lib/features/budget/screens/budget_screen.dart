import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/moneymate_theme.dart';
import '../models/models.dart';
import '../providers.dart';
import 'budget_form_screen.dart';
import 'daily_status_screen.dart';

/// FLT-303: Budget Management Screen.
///
/// Menampilkan:
/// - List Budget Period
/// - Status Budget (Aktif / Selesai)
/// - Default Budget Indicator
/// - Aksi: Set Default, Edit, Delete
///
/// Mendukung tiga state:
/// - **Loading**: Skeleton cards
/// - **Error**: Pesan error + retry
/// - **Data**: List budget cards, empty state jika kosong
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(budgetPeriodsProvider);
    try {
      await ref.read(budgetPeriodsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetPeriodsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BudgetFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: MoneyMateTheme.accent,
        backgroundColor: MoneyMateTheme.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---- Header ------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Budget',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Kelola anggaran dan pantau batas pengeluaran Anda.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // ---- Content -----------------------------------------------
                state.when(
                  loading: () => const _LoadingState(),
                  error: (err, _) => _ErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(budgetPeriodsProvider),
                  ),
                  data: (response) {
                    if (response.data.isEmpty) {
                      return const _EmptyState();
                    }
                    return _BudgetList(budgets: response.data);
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}

}

// ---------------------------------------------------------------------------
// Loading State — skeleton cards
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BudgetCardSkeleton(),
        ),
      ),
    );
  }
}

class _BudgetCardSkeleton extends StatefulWidget {
  @override
  State<_BudgetCardSkeleton> createState() => _BudgetCardSkeletonState();
}

class _BudgetCardSkeletonState extends State<_BudgetCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) => AnimatedBuilder(
        animation: _opacity,
        builder: (_, __) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _opacity.value),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _opacity.value / 2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MoneyMateTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _bar(160, 16),
              const Spacer(),
              _bar(52, 22),
            ]),
            const SizedBox(height: 12),
            _bar(120, 12),
            const SizedBox(height: 8),
            _bar(200, 12),
            const SizedBox(height: 14),
            _bar(double.infinity, 6),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.error_outline, color: MoneyMateTheme.danger, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gagal memuat budget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MoneyMateTheme.danger,
                        fontSize: 15,
                      ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MoneyMateTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              color: MoneyMateTheme.accent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada budget period',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat budget period pertama Anda\nuntuk mulai melacak pengeluaran.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget List
// ---------------------------------------------------------------------------

class _BudgetList extends StatelessWidget {
  const _BudgetList({required this.budgets});
  final List<BudgetPeriod> budgets;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: budgets
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetCard(budget: b),
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget Card
// ---------------------------------------------------------------------------

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.budget});
  final BudgetPeriod budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationState = ref.watch(budgetPeriodMutationProvider);
    final isMutating = mutationState.isLoading;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyStatusScreen(budgetPeriodId: budget.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: budget.isDefault
                ? MoneyMateTheme.accent.withValues(alpha: 0.6)
                : MoneyMateTheme.border,
            width: budget.isDefault ? 1.5 : 1,
          ),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header -------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama budget
                      Text(
                        budget.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badges: Default + Status
                      Wrap(
                        spacing: 6,
                        children: [
                          if (budget.isDefault) const _DefaultBadge(),
                          _StatusChip(isActive: budget.isActive),
                          if (budget.categoryName != null)
                            _CategoryChip(name: budget.categoryName!),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions menu
                _ActionsMenu(budget: budget, isMutating: isMutating),
              ],
            ),
          ),
          // ---- Budget info --------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total budget
                Text(
                  _formatRupiah(budget.totalBudget),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        color: MoneyMateTheme.accent,
                      ),
                ),
                const SizedBox(height: 4),
                // Harian
                Text(
                  '${_formatRupiah(budget.dailyBudgetBase)}/hari · ${budget.workingDaysCount} hari kerja',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                // Tanggal
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: MoneyMateTheme.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_formatDate(budget.startDate)} – ${_formatDate(budget.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ---- Budget system chip ------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: _BudgetSystemChip(system: budget.budgetSystem),
          ),
        ],
      ),
    ),
  );
}
}


// ---------------------------------------------------------------------------
// Budget Card Action Menu
// ---------------------------------------------------------------------------

class _ActionsMenu extends ConsumerWidget {
  const _ActionsMenu({required this.budget, required this.isMutating});
  final BudgetPeriod budget;
  final bool isMutating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_BudgetAction>(
      enabled: !isMutating,
      icon: Icon(
        Icons.more_vert,
        color: MoneyMateTheme.textSecondary,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: MoneyMateTheme.surface,
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (_) => [
        if (!budget.isDefault)
          PopupMenuItem(
            value: _BudgetAction.setDefault,
            child: _MenuRow(
              icon: Icons.star_rounded,
              label: 'Jadikan Default',
              color: MoneyMateTheme.warning,
            ),
          ),
        PopupMenuItem(
          value: _BudgetAction.edit,
          child: _MenuRow(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: MoneyMateTheme.accent,
          ),
        ),
        PopupMenuItem(
          value: _BudgetAction.delete,
          child: _MenuRow(
            icon: Icons.delete_rounded,
            label: 'Hapus',
            color: MoneyMateTheme.danger,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _BudgetAction action,
  ) async {
    final notifier = ref.read(budgetPeriodMutationProvider.notifier);
    switch (action) {
      case _BudgetAction.setDefault:
        await _doSetDefault(context, ref, notifier);
      case _BudgetAction.edit:
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BudgetFormScreen(budget: budget),
            ),
          );
        }

      case _BudgetAction.delete:
        if (context.mounted) _showDeleteDialog(context, ref, notifier);
    }
  }

  Future<void> _doSetDefault(
    BuildContext context,
    WidgetRef ref,
    BudgetPeriodMutationNotifier notifier,
  ) async {
    await notifier.setDefault(budget.id);
    if (context.mounted) {
      final state = ref.read(budgetPeriodMutationProvider);
      if (state.hasError) {
        _showSnackBar(context, 'Gagal: ${state.error}', isError: true);
      } else {
        _showSnackBar(context, '"${budget.name}" dijadikan default.');
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    BudgetPeriodMutationNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MoneyMateTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Budget'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: MoneyMateTheme.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Hapus budget '),
              TextSpan(
                text: '"${budget.name}"',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '?\n\nTindakan ini tidak dapat dibatalkan.'),
              if (budget.isDefault)
                const TextSpan(
                  text:
                      '\n\n⚠️ Ini adalah budget default. Budget default akan dipindahkan ke budget lainnya.',
                  style: TextStyle(color: MoneyMateTheme.warning),
                ),
            ],
          ),
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
              await notifier.delete(budget.id);
              if (context.mounted) {
                final state = ref.read(budgetPeriodMutationProvider);
                if (state.hasError) {
                  _showSnackBar(context, 'Gagal: ${state.error}',
                      isError: true);
                } else {
                  _showSnackBar(context, '"${budget.name}" berhasil dihapus.');
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }



  void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? MoneyMateTheme.danger : MoneyMateTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

enum _BudgetAction { setDefault, edit, delete }

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Bottom Sheet
// ---------------------------------------------------------------------------

class _EditBudgetSheet extends ConsumerStatefulWidget {
  const _EditBudgetSheet({required this.budget});
  final BudgetPeriod budget;

  @override
  ConsumerState<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<_EditBudgetSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late String _budgetSystem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.budget.name);
    _totalCtrl = TextEditingController(
      text: widget.budget.totalBudget.toStringAsFixed(0),
    );
    _startCtrl = TextEditingController(text: widget.budget.startDate);
    _endCtrl = TextEditingController(text: widget.budget.endDate);
    _budgetSystem = widget.budget.budgetSystem;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final totalStr = _totalCtrl.text.trim();
    final start = _startCtrl.text.trim();
    final end = _endCtrl.text.trim();

    if (name.isEmpty || totalStr.isEmpty || start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi.')),
      );
      return;
    }

    final total = double.tryParse(totalStr);
    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total budget harus angka positif.')),
      );
      return;
    }

    setState(() => _saving = true);

    final request = UpdateBudgetPeriodRequest(
      name: name,
      totalBudget: total,
      startDate: start,
      endDate: end,
      budgetSystem: _budgetSystem,
    );

    await ref
        .read(budgetPeriodMutationProvider.notifier)
        .updateBudgetPeriod(widget.budget.id, request);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      final state = ref.read(budgetPeriodMutationProvider);
      final messenger = ScaffoldMessenger.of(context);
      if (state.hasError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal: ${state.error}'),
            backgroundColor: MoneyMateTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Budget berhasil diperbarui.'),
            backgroundColor: MoneyMateTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
            'Edit Budget',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          // Nama
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Budget'),
          ),
          const SizedBox(height: 14),
          // Total budget
          TextField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Budget (Rp)',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 14),
          // Tanggal mulai
          TextField(
            controller: _startCtrl,
            decoration:
                const InputDecoration(labelText: 'Tanggal Mulai (YYYY-MM-DD)'),
          ),
          const SizedBox(height: 14),
          // Tanggal selesai
          TextField(
            controller: _endCtrl,
            decoration: const InputDecoration(
                labelText: 'Tanggal Selesai (YYYY-MM-DD)'),
          ),
          const SizedBox(height: 14),
          // Budget system
          DropdownButtonFormField<String>(
            initialValue: _budgetSystem,
            dropdownColor: MoneyMateTheme.surface,
            decoration: const InputDecoration(labelText: 'Sistem Budget'),
            items: const [
              DropdownMenuItem(
                  value: 'nothing', child: Text('Tidak ada (nothing)')),
              DropdownMenuItem(
                  value: 'carry_over', child: Text('Carry Over')),
              DropdownMenuItem(value: 'invest', child: Text('Invest')),
            ],
            onChanged: (v) => setState(() => _budgetSystem = v ?? _budgetSystem),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip / Badge widgets
// ---------------------------------------------------------------------------

/// Badge "Default" berwarna aksen.
class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MoneyMateTheme.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_rounded, size: 11, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Default',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip status Aktif / Selesai.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? MoneyMateTheme.success : MoneyMateTheme.textSecondary;
    final label = isActive ? 'Aktif' : 'Selesai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Chip kategori (jika ada).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MoneyMateTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MoneyMateTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: MoneyMateTheme.warning,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Chip sistem budget.
class _BudgetSystemChip extends StatelessWidget {
  const _BudgetSystemChip({required this.system});
  final String system;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (system) {
      'carry_over' => ('Carry Over', MoneyMateTheme.accent),
      'invest' => ('Invest', MoneyMateTheme.success),
      _ => ('Standard', MoneyMateTheme.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatRupiah(double amount) {
  final intPart = amount.toInt();
  final str = intPart.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return 'Rp ${buffer.toString()}';
}

String _formatDate(String iso) {
  // "2025-06-01" → "1 Jun 2025"
  try {
    final dt = DateTime.parse(iso);
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  } catch (_) {
    return iso;
  }
}

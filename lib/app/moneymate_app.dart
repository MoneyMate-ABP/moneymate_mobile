import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session.dart';
import '../core/providers.dart';
import '../features/budget/screens/budget_screen.dart';
import '../features/categories/screens/categories_screen.dart';
import '../features/dashboard/providers.dart';
import '../features/dashboard/widgets/budget_status_list.dart';
import '../features/dashboard/widgets/dashboard_summary_card.dart';
import '../features/dashboard/widgets/recent_transactions.dart';
import '../features/profile/screens/profile_screen.dart';
import 'auth_screen.dart';
import 'theme/moneymate_theme.dart';
import '../features/transactions/screens/transaction_list_screen.dart';
import '../features/notification/providers.dart';
import '../features/notification/screens/notification_history_screen.dart';


class MoneyMateApp extends ConsumerWidget {
  const MoneyMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: MoneyMateTheme.dark(),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends ConsumerWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(authControllerProvider);
    return sessionState.when(
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => const AuthScreen(),
      data: (session) {
        if (session == null) {
          return const AuthScreen();
        }
        return AppNavigationShell(session: session);
      },
    );
  }
}

class AppNavigationShell extends ConsumerStatefulWidget {
  const AppNavigationShell({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends ConsumerState<AppNavigationShell> {
  late final List<Widget> _pages = [
    DashboardScreen(session: widget.session),
    const TransactionListScreen(),
    BudgetScreen(),
    const CategoriesScreen(),
    ProfileScreen(session: widget.session),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: currentIndex, children: _pages),
      ),
      bottomNavigationBar: _GlassNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}

class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueSetter<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      _NavBarItem(
        icon: Icons.swap_horiz_outlined,
        activeIcon: Icons.swap_horiz_rounded,
        label: 'Transaksi',
      ),
      _NavBarItem(
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart_rounded,
        label: 'Budget',
      ),
      _NavBarItem(
        icon: Icons.category_outlined,
        activeIcon: Icons.category_rounded,
        label: 'Kategori',
      ),
      _NavBarItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'Profil',
      ),
    ];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF16162D).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: _NavBarItemWidget(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem {
  _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavBarItemWidget extends StatefulWidget {
  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavBarItemWidget> createState() => _NavBarItemWidgetState();
}

class _NavBarItemWidgetState extends State<_NavBarItemWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? MoneyMateTheme.accent
        : Colors.white.withValues(alpha: 0.4);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isSelected ? widget.item.activeIcon : widget.item.icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              widget.item.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              width: widget.isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: MoneyMateTheme.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MoneyMateTheme.accent.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// FLT-302: Dashboard screen dengan ringkasan saldo, pemasukan,
/// pengeluaran, pengeluaran hari ini, dan sisa saldo hari ini.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(notificationHistoryProvider);
    // Tunggu provider selesai refresh.
    try {
      await ref.read(dashboardSummaryProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: MoneyMateTheme.accent,
      backgroundColor: MoneyMateTheme.surface,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---- Header -----------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MoneyMate Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const _NotificationBellButton(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Halo, ${widget.session.user.name}. Selamat datang kembali! 👋',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // ---- FLT-302: Summary Card ---------------------------------
                const DashboardSummaryCard(),
                const BudgetStatusList(),
                const RecentTransactions(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


// TransactionsScreen is now TransactionListScreen (see features/transactions/screens/).

class _NotificationBellButton extends ConsumerWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger initial notification fetch
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationHistoryScreen(),
              ),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: MoneyMateTheme.danger,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}





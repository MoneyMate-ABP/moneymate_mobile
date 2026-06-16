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
  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.swap_horiz_outlined),
      selectedIcon: Icon(Icons.swap_horiz),
      label: 'Transaksi',
    ),
    NavigationDestination(
      icon: Icon(Icons.pie_chart_outline),
      selectedIcon: Icon(Icons.pie_chart),
      label: 'Budget',
    ),
    NavigationDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category),
      label: 'Kategori',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

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
      body: SafeArea(
        child: IndexedStack(index: currentIndex, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _destinations,
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
                const SizedBox(height: 32),
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





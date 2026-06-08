import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session.dart';
import '../core/providers.dart';
import 'auth_screen.dart';
import 'theme/moneymate_theme.dart';
import '../features/transactions/screens/transaction_list_screen.dart';

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

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({required this.session, super.key});

  final AuthSession session;

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;

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
    CategoriesScreen(),
    ProfileScreen(session: widget.session),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _destinations,
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Halo, ${session.user.name}. Selamat datang kembali di MoneyMate.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Keuangan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saldo, pengeluaran, dan pemasukan akan muncul di sini.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.show_chart,
                    color: MoneyMateTheme.accent,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TransactionsScreen is now TransactionListScreen (see features/transactions/screens/).

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Atur anggaran bulanan dan pantau batas pengeluaran Anda.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Bulanan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.64,
                    color: MoneyMateTheme.accent,
                    backgroundColor: Colors.white12,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '64% digunakan dari anggaran Rp 3.000.000',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kategori', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Pengelompokan kategori pemasukan dan pengeluaran.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _CategoryTile(
                  title: 'Gaji',
                  type: 'Pemasukan',
                  color: MoneyMateTheme.success,
                ),
                const SizedBox(height: 12),
                _CategoryTile(
                  title: 'Makanan',
                  type: 'Pengeluaran',
                  color: MoneyMateTheme.danger,
                ),
                const SizedBox(height: 12),
                _CategoryTile(
                  title: 'Transport',
                  type: 'Pengeluaran',
                  color: MoneyMateTheme.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MoneyMateTheme.accent,
                    child: Text(
                      session.user.name.isNotEmpty
                          ? session.user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.user.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          session.user.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Keluar dari akun Anda'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.type,
    required this.color,
  });

  final String title;
  final String type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.label, color: color),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(type, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

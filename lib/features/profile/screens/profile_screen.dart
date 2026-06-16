import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/providers.dart';
import '../../../core/notification/notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await NotificationService.instance.setNotificationsEnabled(value);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MoneyMateTheme.surface,
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin logout dari MoneyMate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MoneyMateTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).clearSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),

              // User Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: MoneyMateTheme.accent,
                        child: Text(
                          widget.session.user.name.isNotEmpty
                              ? widget.session.user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.user.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.session.user.email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MoneyMateTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notification Settings Card
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    _notificationsEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: _notificationsEnabled
                        ? MoneyMateTheme.accent
                        : MoneyMateTheme.textSecondary,
                  ),
                  title: const Text(
                    'Pengingat Harian',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Push notification jam 08:00 pagi'),
                  value: _notificationsEnabled,
                  onChanged: _isLoading ? null : _toggleNotifications,
                  activeColor: MoneyMateTheme.accent,
                ),
              ),
              const SizedBox(height: 12),

              // Logout Row
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: MoneyMateTheme.danger),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: MoneyMateTheme.danger, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Keluar dari akun Anda'),
                  trailing: const Icon(Icons.chevron_right, color: MoneyMateTheme.danger),
                  onTap: () => _logout(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session.dart';
import '../core/auth/auth_repository.dart';
import '../core/network/api_exception.dart';
import '../core/providers.dart';
import 'theme/moneymate_theme.dart';

enum AuthMode { login, register }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _mode == AuthMode.register
        ? _nameController.text.trim()
        : email.split('@').first;

    try {
      final repo = ref.read(authRepositoryProvider);
      final AuthSession session = _mode == AuthMode.login
          ? await repo.login(email: email, password: password)
          : await repo.register(name: name, email: email, password: password);

      await ref.read(authControllerProvider.notifier).setSession(session);
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Terjadi kesalahan. Periksa kembali data Anda.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: MoneyMateTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    if (_mode == AuthMode.register && (value == null || value.trim().isEmpty)) {
      return 'Nama lengkap wajib diisi.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi.';
    }
    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Masukkan alamat email valid.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_mode == AuthMode.register) {
      if (value == null || value.isEmpty) {
        return 'Konfirmasi kata sandi wajib diisi.';
      }
      if (value != _passwordController.text) {
        return 'Kata sandi tidak sama.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == AuthMode.register;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  Text(
                    'MoneyMate',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: MoneyMateTheme.accent,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRegister
                        ? 'Daftar untuk mulai mengatur keuangan Anda.'
                        : 'Masuk ke akun Anda untuk melihat transaksi dan budget.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (isRegister) ...[
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  hintText: 'Masukkan nama lengkap Anda',
                                ),
                                validator: _validateName,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'nama@domain.com',
                              ),
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Kata Sandi',
                                hintText: 'Minimal 8 karakter',
                              ),
                              obscureText: true,
                              validator: _validatePassword,
                              textInputAction: isRegister
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                            ),
                            if (isRegister) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Konfirmasi Kata Sandi',
                                  hintText: 'Ulangi kata sandi Anda',
                                ),
                                obscureText: true,
                                validator: _validateConfirmPassword,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isRegister
                                            ? 'Daftar Sekarang'
                                            : 'Masuk',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isRegister
                                      ? 'Sudah punya akun?'
                                      : 'Belum punya akun?',
                                  style: theme.textTheme.bodySmall,
                                ),
                                TextButton(
                                  onPressed: _isSubmitting ? null : _toggleMode,
                                  child: Text(isRegister ? 'Masuk' : 'Daftar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Akses cepat ke ringkasan keuangan, kategori, dan budget. Pilih mode dan lanjutkan.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

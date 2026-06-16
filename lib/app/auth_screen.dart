import 'dart:ui';
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
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MoneyMateTheme.accent.withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MoneyMateTheme.success.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [MoneyMateTheme.accent, Color(0xFF8B85FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: MoneyMateTheme.accent.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'MoneyMate',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Colors.white, Color(0xFFC5C0FF)],
                            ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? 'Daftar untuk mulai mengatur keuangan Anda.'
                            : 'Masuk ke akun Anda untuk melihat transaksi dan budget.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: MoneyMateTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
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
                                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
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
                                      prefixIcon: Icon(Icons.email_outlined, size: 20),
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
                                      hintText: 'Minimal 6 karakter',
                                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
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
                                        prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
                                      ),
                                      obscureText: true,
                                      validator: _validateConfirmPassword,
                                      textInputAction: TextInputAction.done,
                                    ),
                                  ],
                                  const SizedBox(height: 28),
                                  BounceButton(
                                    onPressed: _isSubmitting ? null : _submit,
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [MoneyMateTheme.accent, Color(0xFF5346E0)],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: MoneyMateTheme.accent.withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
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
                                              isRegister ? 'Daftar Sekarang' : 'Masuk',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isRegister ? 'Sudah punya akun?' : 'Belum punya akun?',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      TextButton(
                                        onPressed: _isSubmitting ? null : _toggleMode,
                                        style: TextButton.styleFrom(
                                          foregroundColor: MoneyMateTheme.accent,
                                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        child: Text(isRegister ? 'Masuk' : 'Daftar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Akses cepat ke ringkasan keuangan, kategori, dan budget. Pilih mode dan lanjutkan.',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BounceButton extends StatefulWidget {
  const BounceButton({
    required this.child,
    required this.onPressed,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

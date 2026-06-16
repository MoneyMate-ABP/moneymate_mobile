import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          statusCode: 0,
          message: 'Gagal mengambil ID Token dari Google.',
        );
      }

      final repo = ref.read(authRepositoryProvider);
      final AuthSession session = await repo.loginWithGoogleToken(idToken: idToken);
      await ref.read(authControllerProvider.notifier).setSession(session);
    } catch (e) {
      _showDevBypassDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showDevBypassDialog(String originalError) {
    final emailController = TextEditingController(text: 'dev.user@example.com');
    final nameController = TextEditingController(text: 'Developer User');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MoneyMateTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: MoneyMateTheme.warning),
              const SizedBox(width: 8),
              const Text(
                'Google Login Dev Bypass',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Google Sign-In asli gagal karena konfigurasi Firebase client ID (google-services.json / GoogleService-Info.plist) belum disetup di project lokal ini.',
                  style: TextStyle(color: MoneyMateTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Detail Error: $originalError',
                    style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Masukkan email & nama untuk login simulasi (Bypass):',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Simulated Email',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Simulated Name',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: MoneyMateTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MoneyMateTheme.accent,
                minimumSize: const Size(100, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isSubmitting = true;
                });
                try {
                  final repo = ref.read(authRepositoryProvider);
                  AuthSession session;
                  try {
                    session = await repo.login(
                      email: emailController.text.trim(),
                      password: 'DevBypassPassword123!',
                    );
                  } catch (_) {
                    session = await repo.register(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: 'DevBypassPassword123!',
                    );
                  }
                  await ref.read(authControllerProvider.notifier).setSession(session);
                } catch (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bypass gagal: ${err.toString()}'),
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
              },
              child: const Text('Simulasi Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
                                    children: [
                                      const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          isRegister ? 'Atau daftar dengan' : 'Atau masuk dengan',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: MoneyMateTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  BounceButton(
                                    onPressed: _isSubmitting ? null : _loginWithGoogle,
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const _GoogleLogo(),
                                          const SizedBox(width: 12),
                                          Text(
                                            isRegister ? 'Daftar dengan Google' : 'Masuk dengan Google',
                                            style: const TextStyle(
                                              color: Color(0xFF1E1E2C),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
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

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.butt;
    
    final rect = Rect.fromLTWH(0, 0, w, h);
    
    // Red segment
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.4, 1.4, false, paint);
    
    // Yellow segment
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.9, 1.5, false, paint);
    
    // Green segment
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.6, false, paint);
    
    // Blue segment
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.8, 1.6, false, paint);
    
    // Middle bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w / 2, h / 2 - 1.75, w / 2, 3.5), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

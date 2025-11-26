// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempest_store/screens/page/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _loading = false;
  bool _checkingSession = true;

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _afterSignIn(user);
      return;
    }
    if (mounted) setState(() => _checkingSession = false);
  }

  Future<void> _afterSignIn(User user) async {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const SplashScreen(nextRoute: '/dashboard'),
      ),
      (r) => false,
    );
  }

  // ===================================================
  //                  FIXED LOGIN FUNCTION
  // ===================================================
  Future<void> _login() async {
    // Reset error setiap kali login
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final email = _emailCtl.text.trim();
    final password = _passwordCtl.text.trim();
    final client = Supabase.instance.client;

    try {
      // 1️⃣ Cek email di tabel public.users
      final userRow = await client
          .from('users')
          .select('auth_uid')
          .eq('email', email)
          .maybeSingle();

      if (userRow == null) {
        setState(() {
          _emailError = "Email tidak ditemukan";
          _passwordError = null; // reset password error
        });
        _formKey.currentState!.validate();
        return;
      }

      // 2️⃣ Login ke Supabase Auth
      try {
        final loginResp = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (loginResp.user == null) {
          setState(() {
            _passwordError = "Password salah";
            _emailError = null; // reset email error
          });
          _formKey.currentState!.validate();
          return;
        }

        // 3️⃣ Login sukses
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login berhasil")),
        );

        // reset errors sukses
        setState(() {
          _emailError = null;
          _passwordError = null;
        });

        await _afterSignIn(loginResp.user!);

      } on AuthApiException catch (e) {
        if (e.code == "invalid_credentials") {
          setState(() {
            _passwordError = "Password salah";
            _emailError = null; // reset email error
          });
          _formKey.currentState!.validate();
          return;
        }

        setState(() {
          _emailError = "Terjadi kesalahan server.";
        });
        _formKey.currentState!.validate();
      }

    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF3F598C),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final maxWidth = width < 440 ? width - 32 : 420.0;
    final circleSize = width > 600 ? 150.0 : 120.0;

    return Scaffold(
      backgroundColor: const Color(0xFF3F598C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.only(
                      top: circleSize / 2 + 24,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Tempest Store',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Log-In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // EMAIL FIELD
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _emailCtl,
                            decoration: InputDecoration(
                              hintText: 'nama@email.com',
                              filled: true,
                              fillColor: Colors.white,
                              errorText: _emailError,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Email wajib diisi";
                              }
                              return _emailError;
                            },
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                          ),

                          const SizedBox(height: 18),

                          // PASSWORD FIELD
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _passwordCtl,
                            obscureText: true,
                            focusNode: _passwordFocus,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              errorText: _passwordError,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Password wajib diisi";
                              }
                              return _passwordError;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),

                          const SizedBox(height: 28),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF91C4D9),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Masuk",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 26),
                          const Text(
                            "v1.0.0 • © 2025 Tempest Store",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: -(circleSize / 2),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFF91C4D9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE1E8EB),
                            width: 4,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/logo.png",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ),
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

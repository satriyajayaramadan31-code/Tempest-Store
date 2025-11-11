// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempest_store/services/supabase_service.dart';
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
  bool _loading = false;

  // menunggu pemeriksaan session saat pertama kali buka screen
  bool _checkingSession = true;

  final SupabaseService supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  dynamic _firstOrNull(dynamic resp) {
    if (resp == null) return null;
    if (resp is List) return resp.isNotEmpty ? resp.first : null;
    return resp;
  }

  Future<void> _checkExistingSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // user sudah login: lakukan sinkronisasi (jika perlu) lalu tampilkan splash dulu -> dashboard
      await _afterSignIn(user, pushSplash: true);
      return;
    }
    // tidak ada session -> tampilkan form
    if (mounted) setState(() => _checkingSession = false);
  }

  /// Jika [pushSplash] true, setelah sinkronisasi kita akan menampilkan SplashScreen
  /// dengan nextRoute '/dashboard' lalu clear stack.
  Future<void> _afterSignIn(User user, {bool pushSplash = false}) async {
    String role = 'kasir';
    try {
      final String userEmail = user.email ?? '';

      dynamic byUidResp = await Supabase.instance.client
          .from('users')
          .select('id, role, email, auth_uid')
          .eq('auth_uid', user.id)
          .maybeSingle();

      final byUid = _firstOrNull(byUidResp);
      if (byUid != null) {
        final r = (byUid['role'] ?? '').toString().trim();
        if (r.isNotEmpty) role = r;
      } else if (userEmail.isNotEmpty) {
        dynamic byEmailResp = await Supabase.instance.client
            .from('users')
            .select('id, role, email, auth_uid')
            .eq('email', userEmail)
            .maybeSingle();

        final byEmail = _firstOrNull(byEmailResp);
        if (byEmail != null) {
          final r = (byEmail['role'] ?? '').toString().trim();
          if (r.isNotEmpty) role = r;
          final dbAuthUid = (byEmail['auth_uid'] ?? '').toString();
          if (dbAuthUid.isEmpty || dbAuthUid != user.id) {
            try {
              await Supabase.instance.client.from('users').update({'auth_uid': user.id}).eq('id', byEmail['id']);
            } catch (_) {}
          }
        } else {
          final existing = await Supabase.instance.client.from('users').select('id');
          final bool usersEmpty = (existing is List && existing.isEmpty);
          final String assignRole = usersEmpty ? 'admin' : 'kasir';
          try {
            await Supabase.instance.client.from('users').insert({
              'email': userEmail,
              'auth_uid': user.id,
              'role': assignRole,
            });
            role = assignRole;
          } catch (_) {}
        }
      }
    } catch (e, st) {
      debugPrint('LoginScreen._afterSignIn error: $e\n$st');
    }

    if (!mounted) return;
    debugPrint('LoginScreen: resolved role = $role');

    if (pushSplash) {
      // bersihkan stack dan tampilkan splash terlebih dulu, lalu dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen(nextRoute: '/dashboard')),
        (r) => false,
      );
    } else {
      // langsung ke dashboard
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final res = await supabaseService.signIn(_emailCtl.text.trim(), _passwordCtl.text.trim());
      final dynamic user = (res as dynamic).user;

      if (user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login berhasil')));
        // paksa tampilkan splash dulu lalu dashboard
        await _afterSignIn(user as User, pushSplash: true);
      } else {
        if (!mounted) return;
        final error = (res as dynamic).error;
        final msg = error != null ? error.toString() : 'Login gagal';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika masih mengecek session, tampilkan loading fullscreen agar form tidak sempat muncul
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF3F598C),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // UI form (sama seperti sebelumnya)
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final maxWidth = screenWidth < 440 ? screenWidth - 32 : 420.0;
    final circleSize = screenWidth > 600 ? 150.0 : 120.0;

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
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.only(top: circleSize / 2 + 24, left: 20, right: 20, bottom: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          const Text('Tempest Store', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87)),
                          const SizedBox(height: 8),
                          const Text('Log-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Email', style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('email'),
                            controller: _emailCtl,
                            decoration: InputDecoration(
                              hintText: 'nama@email.com',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Password', style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('password'),
                            controller: _passwordCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF91C4D9), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Masuk', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Text('v1.0.0 • © 2025 Tempest Store', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
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
                        decoration: BoxDecoration(color: const Color(0xFF91C4D9), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE1E8EB), width: 4)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox())),
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

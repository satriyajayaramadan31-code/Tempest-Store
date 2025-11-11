// lib/screens/page/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  /// Jika nextRoute diberikan, setelah menampilkan splash akan diarahkan ke route itu.
  /// Jika tidak diberikan: akan cek session -> '/dashboard' jika sudah login, '/login' jika belum.
  final String? nextRoute;
  final Duration minDuration;

  const SplashScreen({super.key, this.nextRoute, this.minDuration = const Duration(seconds: 2)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _startAndNavigate();
  }

  Future<void> _startAndNavigate() async {
    // pastikan splash tampil minimal durasi
    await Future.delayed(widget.minDuration);

    String dest;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (widget.nextRoute != null && widget.nextRoute!.isNotEmpty) {
        dest = widget.nextRoute!;
      } else {
        dest = (user != null) ? '/dashboard' : '/login';
      }
    } catch (_) {
      dest = '/login';
    }

    if (!mounted) return;
    // bersihkan semua route lalu navigasi ke tujuan (agar tidak ada sisa stack)
    Navigator.of(context).pushNamedAndRemoveUntil(dest, (r) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F598C),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/logo.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

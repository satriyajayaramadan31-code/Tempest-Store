// lib/main.dart
import 'package:flutter/material.dart';
import 'package:tempest_store/services/supabase_service.dart';
import 'package:tempest_store/screens/page/splash_screen.dart';
import 'package:tempest_store/screens/auth/login_screen.dart';
import 'package:tempest_store/screens/page/dashboard_screen.dart';
import 'package:tempest_store/screens/page/kasir_screen.dart';
import 'package:tempest_store/screens/page/produk_screen.dart';
import 'package:tempest_store/screens/page/pelanggan_screen.dart';
import 'package:tempest_store/screens/page/laporan_screen.dart';
import 'package:tempest_store/screens/page/manajemen_user_screen.dart';
import 'package:tempest_store/screens/page/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: null,
      title: 'Kasir App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // Mulai selalu dari SplashScreen
      home: const SplashScreen(),

      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
        '/kasir': (ctx) => const KasirScreen(),
        '/produk': (ctx) => const ProdukScreen(),
        '/pelanggan': (ctx) => const PelangganScreen(),
        '/laporan': (ctx) => const LaporanScreen(),
        '/users': (ctx) => const ManajemenUserScreen(),
        '/settings': (ctx) => const SettingsScreen(),
      },
    );
  }
}

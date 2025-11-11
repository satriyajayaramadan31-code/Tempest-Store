import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Laporan',
      child: const Center(child: Text('Halaman Laporan (placeholder)')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class PelangganScreen extends StatelessWidget {
  const PelangganScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Pelanggan',
      child: const Center(child: Text('Halaman Pelanggan (placeholder)')),
    );
  }
}

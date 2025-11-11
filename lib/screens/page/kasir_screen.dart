import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class KasirScreen extends StatelessWidget {
  const KasirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Kasir',
      child: const Center(child: Text('Halaman Kasir (placeholder)')),
    );
  }
}

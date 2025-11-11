import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class ProdukScreen extends StatelessWidget {
  const ProdukScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Produk',
      child: const Center(child: Text('Halaman Produk (placeholder)')),
    );
  }
}

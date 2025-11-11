import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      child: const Center(child: Text('Halaman Settings (admin only)')),
    );
  }
}

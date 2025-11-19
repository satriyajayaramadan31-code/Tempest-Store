import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempest_store/widgets/side_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String title;
  const AppShell({super.key, required this.child, required this.title});

  Future<String> _fetchRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 'kasir';

      final resp = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('auth_uid', user.id)
          .maybeSingle();

      if (resp != null && resp['role'] != null) {
        return resp['role'].toString();
      }

      final email = user.email;
      if (email != null && email.isNotEmpty) {
        final resp2 = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('email', email)
            .maybeSingle();

        if (resp2 != null && resp2['role'] != null) {
          return resp2['role'].toString();
        }
      }
    } catch (_) {}

    return 'kasir';
  }

  @override
  Widget build(BuildContext context) {
    const Color topBg = Color(0xFF93B9E8);
    const Color borderColor = Color(0xFF3A71A4);

    return Scaffold(
      drawer: const SideBar(),
      appBar: AppBar(
        backgroundColor: topBg,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        foregroundColor: Colors.black87,
        actions: [
          FutureBuilder<String>(
            future: _fetchRole(),
            builder: (context, snapshot) {
              final role = (snapshot.data ?? 'kasir').toLowerCase();
              final asset = role == 'admin'
                  ? 'avatar_admin.png'
                  : 'avatar_kasir.png';

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: SizedBox(
            height: 2,
            width: double.infinity,
            child: ColoredBox(color: borderColor),
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: SafeArea(child: child),
    );
  }
}

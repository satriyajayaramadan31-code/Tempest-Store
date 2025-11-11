import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempest_store/widgets/side_bar.dart';

/// AppShell wraps pages to provide responsive sidebar + consistent AppBar.
class AppShell extends StatelessWidget {
  final Widget child;
  final String title;
  const AppShell({super.key, required this.child, required this.title});

  /// Ambil role user dari tabel `users`.
  Future<String> _fetchRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 'kasir';

      // PRIMARY: ambil berdasarkan auth_uid
      final resp = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('auth_uid', user.id)
          .maybeSingle();

      if (resp != null && resp['role'] != null) {
        return resp['role'].toString();
      }

      // FALLBACK: berdasarkan email
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
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 800;

    const Color topBg = Color(0xFF93B9E8);
    const Color borderColor = Color(0xFF3A71A4);

    // =============================================================
    // DESKTOP / TABLET: Sidebar tetap, AppBar custom
    // =============================================================
    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            const SideBar(),

            Expanded(
              child: Column(
                children: [
                  Container(
                    height: kToolbarHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: const BoxDecoration(
                      color: topBg,
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),

                        // Future avatar
                        FutureBuilder<String>(
                          future: _fetchRole(),
                          builder: (context, snapshot) {
                            final role = (snapshot.data ?? 'kasir').toLowerCase();
                            final asset = role == 'admin'
                                ? 'avatar_admin.png'
                                : 'avatar_kasir.png';

                            return Row(
                              children: [
                                if (width > 900)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color.fromRGBO(255, 255, 255, 0.6),
                                      width: 1.0,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.06),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      asset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(child: SafeArea(child: child)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // =============================================================
    // MOBILE: Drawer + normal AppBar
    // =============================================================
    return Scaffold(
      drawer: const SideBar(),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: topBg,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
      ),
      body: SafeArea(child: child),
    );
  }
}

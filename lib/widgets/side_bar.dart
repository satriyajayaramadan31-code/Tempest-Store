// lib/widgets/side_bar.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempest_store/services/supabase_service.dart';
import 'package:tempest_store/screens/auth/login_screen.dart';

class SideBar extends StatefulWidget {
  final String? forcedRoute;
  const SideBar({super.key, this.forcedRoute});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final SupabaseService _svc = SupabaseService();

  String _role = 'kasir';
  String? _displayName;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  dynamic _firstOrNull(dynamic resp) {
    if (resp == null) return null;
    if (resp is List) return resp.isNotEmpty ? resp.first : null;
    return resp;
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _role = 'guest';
          _displayName = 'User';
          _loading = false;
        });
      }
      return;
    }

    final String userId = user.id;
    final String userEmail = user.email ?? '';

    try {
      dynamic resp;

      final byUidResp = await Supabase.instance.client
          .from('users')
          .select('id, email, role, auth_uid')
          .eq('auth_uid', userId)
          .maybeSingle();

      resp = _firstOrNull(byUidResp);

      if (resp == null && userEmail.isNotEmpty) {
        final byEmailResp = await Supabase.instance.client
            .from('users')
            .select('id, email, role, auth_uid')
            .ilike('email', userEmail)
            .maybeSingle();

        final byEmail = _firstOrNull(byEmailResp);
        if (byEmail != null) {
          final dbAuth = (byEmail['auth_uid'] ?? '').toString();
          if (dbAuth.isEmpty || dbAuth != userId) {
            try {
              await Supabase.instance.client
                  .from('users')
                  .update({'auth_uid': userId})
                  .eq('id', byEmail['id']);
              byEmail['auth_uid'] = userId;
            } catch (_) {}
          }
          resp = byEmail;
        }
      }

      if (resp == null) {
        final existing = await Supabase.instance.client
            .from('users')
            .select('id');

        final usersEmpty = existing is List && existing.isEmpty;
        final role = usersEmpty ? 'admin' : 'kasir';

        final insertResp = await Supabase.instance.client
            .from('users')
            .insert({
              'email': userEmail,
              'auth_uid': userId,
              'role': role,
            })
            .select()
            .maybeSingle();

        resp = _firstOrNull(insertResp);
      }

      if (resp != null) {
        final rawRole = (resp['role'] ?? 'kasir')
            .toString()
            .trim()
            .toLowerCase();
        final em = (resp['email'] ?? '').toString().trim();

        if (mounted) {
          setState(() {
            _role = rawRole;
            _displayName = em.isNotEmpty ? em : 'User';
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _role = 'kasir';
            _displayName = userEmail.isNotEmpty ? userEmail : 'User';
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _role = 'kasir';
          _displayName = userEmail.isNotEmpty ? userEmail : 'User';
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _svc.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  String _currentRouteName(BuildContext ctx) {
    if (widget.forcedRoute != null) return widget.forcedRoute!;
    return ModalRoute.of(ctx)?.settings.name ?? '/dashboard';
  }

  Widget _menuItem({
    required BuildContext ctx,
    required String id,
    required IconData icon,
    required String label,
    required String routeName,
    bool visible = true,
  }) {
    if (!visible) return const SizedBox.shrink();
    final current = _currentRouteName(ctx);
    final selected = current == routeName;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Colors.blue.shade800 : Colors.black87,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w700,
            color:
                selected ? Colors.blue.shade800 : Colors.black87,
          ),
        ),
        onTap: () {
          Navigator.of(ctx).maybePop();
          if (!selected) {
            Navigator.of(ctx).pushReplacementNamed(routeName);
          }
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= 800;

    final String avatarAsset =
        _role == 'admin'
            ? 'avatar_admin.png'
            : 'avatar_kasir.png';

    final content = Column(
      children: [
        if (!isWide)
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _menuItem(
                  ctx: context,
                  id: 'dashboard',
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  routeName: '/dashboard',
                ),
                _menuItem(
                  ctx: context,
                  id: 'kasir',
                  icon: Icons.shopping_cart_checkout_rounded,
                  label: 'Kasir',
                  routeName: '/kasir',
                ),
                _menuItem(
                  ctx: context,
                  id: 'produk',
                  icon: Icons.inventory_2_outlined,
                  label: 'Produk',
                  routeName: '/produk',
                ),
                _menuItem(
                  ctx: context,
                  id: 'pelanggan',
                  icon: Icons.people_alt_rounded,
                  label: 'Pelanggan',
                  routeName: '/pelanggan',
                ),
                _menuItem(
                  ctx: context,
                  id: 'laporan',
                  icon: Icons.description_outlined,
                  label: 'Laporan',
                  routeName: '/laporan',
                ),
                _menuItem(
                  ctx: context,
                  id: 'manajemen_user',
                  icon: Icons.manage_accounts_rounded,
                  label: 'Manajemen User',
                  routeName: '/users',
                  visible: _role == 'admin',
                ),
                _menuItem(
                  ctx: context,
                  id: 'settings',
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  routeName: '/settings',
                  visible: _role == 'admin',
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: AssetImage(avatarAsset),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        child: LinearProgressIndicator(),
                      )
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: Colors.blue.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return isWide
        ? Container(
            width: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBFC),
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SafeArea(child: content),
          )
        : Drawer(
            child: SafeArea(child: content),
          );
  }
}

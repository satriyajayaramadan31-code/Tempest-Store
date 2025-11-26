// lib/screens/page/manajemen_user_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempest_store/widgets/app_shell.dart';
import 'package:tempest_store/widgets/add_user.dart';
import 'package:tempest_store/widgets/edit_user.dart';

class ManajemenUserScreen extends StatefulWidget {
  const ManajemenUserScreen({super.key});

  @override
  State<ManajemenUserScreen> createState() => _ManajemenUserScreenState();
}

class _ManajemenUserScreenState extends State<ManajemenUserScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchCtl = TextEditingController();

  bool _loading = true;
  String? _error;
  String _query = '';
  List<Map<String, dynamic>> _users = [];

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  // -----------------------------
  // REALTIME SUBSCRIPTION
  // -----------------------------
  void _subscribeRealtime() {
    _channel = supabase
        .channel('public:users')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (_) => _loadUsers(),
        )
        .subscribe();
  }

  // -----------------------------
  // LOAD USERS
  // -----------------------------
  Future<void> _loadUsers() async {
    try {
      final data = await supabase
          .from('users')
          .select('id, username, email, role, auth_uid')
          .order('username') as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _users = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Gagal memuat pengguna: $e";
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      return u['username'].toString().toLowerCase().contains(q) ||
          u['email'].toString().toLowerCase().contains(q) ||
          u['role'].toString().toLowerCase().contains(q);
    }).toList();
  }

  // =======================================================
  // DELETE USER VIA EDGE FUNCTION
  // =======================================================
  Future<void> _deleteUser(int id) async {
    final user = _users.firstWhere((u) => u['id'] == id, orElse: () => {});
    if (user.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Pengguna?"),
        content: Text("Apakah kamu yakin ingin menghapus ${user['username']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authUid = user['auth_uid'];
      final adminUid = supabase.auth.currentUser?.id;
      final accessToken = supabase.auth.currentSession?.accessToken;

      if (authUid == null || adminUid == null || accessToken == null) {
        throw "auth_uid/admin_uid/token null";
      }

      final response = await supabase.functions.invoke(
        'delete-user',
        body: {'target_uid': authUid, 'admin_uid': adminUid},
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.status != 200) {
        final msg = response.data?['error'] ?? "Gagal menghapus user";
        throw msg;
      }

      if (!mounted) return;
      _showDeletedPopup();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus: $e")),
      );
      log("DELETE ERROR: $e");
    }
  }

  // =======================================================
  // POPUP DELETE SUKSES (ROW CLOSE, ICON & TEXT CENTER)
  // =======================================================
  void _showDeletedPopup() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF3A71A4), width: 2),
          ),
          child: SizedBox(
            width: 330,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row with close button aligned to end (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Centered icon
                  const Icon(Icons.check_circle, size: 110, color: Colors.green),

                  const SizedBox(height: 18),

                  // Centered text
                  const Text(
                    "Pengguna Berhasil\nDihapus",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =======================================================
  // UI
  // =======================================================
  @override
  Widget build(BuildContext context) {
    const topBg = Color(0xFF93B9E8);
    const borderColor = Color(0xFF3A71A4);

    return AppShell(
      title: "Manajemen User",
      child: Container(
        color: topBg,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Manajemen User",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total: ${_users.length} user",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const AddUserDialog(),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Tambah User"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF91C4D9),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      side: const BorderSide(
                                        color: Color(0xFF3A71A4),
                                        width: 1,
                                      ),                               
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              TextField(
                                controller: _searchCtl,
                                onChanged: (v) =>
                                    setState(() => _query = v.trim()),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: "Cari nama / email",
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: borderColor),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              _buildTable(borderColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTable(Color borderColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 800,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1.5),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text("Nama",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 4,
                      child: Text("Email",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 2,
                      child: Text("Role",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 2,
                      child: Text("Aksi",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            ..._filtered.map((u) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 1.2),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text(u['username'] ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        flex: 4,
                        child: Text(u['email'] ?? '-',
                            style: const TextStyle(color: Colors.black54))),
                    Expanded(
                        flex: 2,
                        child: Text(u['role'] ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold))),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          _actionBtn(
                            icon: Icons.edit_outlined,
                            color: Colors.black,
                            onTap: () async {
                              final res = await showDialog(
                                context: context,
                                builder: (_) => EditUserDialog(user: u),
                              );
                              if (res is Map) {
                                await supabase
                                    .from('users')
                                    .update({
                                      'username': res['username'],
                                      'email': res['email'],
                                      'role': res['role'],
                                    })
                                    .eq('id', u['id']);
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          _actionBtn(
                            icon: Icons.delete_outline,
                            color: Colors.red,
                            onTap: () => _deleteUser(u['id']),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF3A71A4), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

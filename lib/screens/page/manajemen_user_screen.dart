// lib/screens/page/manajemen_user_screen.dart
import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManajemenUserScreen extends StatefulWidget {
  const ManajemenUserScreen({super.key});

  @override
  State<ManajemenUserScreen> createState() => _ManajemenUserScreenState();
}

class _ManajemenUserScreenState extends State<ManajemenUserScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';
  bool _loading = true;

  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('nama, email, role')
          .order('nama', ascending: true);

      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('ERROR load users: $e');
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allUsers;

    return _allUsers.where((u) {
      final n = (u['nama'] ?? '').toString().toLowerCase();
      final e = (u['email'] ?? '').toString().toLowerCase();
      return n.contains(q) || e.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color topBg = Color(0xFF93B9E8);
    const Color borderColor = Color(0xFF3A71A4);

    return AppShell(
      title: 'Manajemen User',
      child: Container(
        color: topBg.withOpacity(0.12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: topBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Manajemen Pengguna',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total ada ${_allUsers.length} Pengguna',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('+ Tambah Pengguna'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SEARCH
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: borderColor.withOpacity(0.25)),
                      ),
                      child: TextField(
                        controller: _searchCtl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Cari nama atau email',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // TABLE
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: borderColor.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          // HEADER BAR
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: borderColor.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Nama',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Email',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Role',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ..._filtered.map((u) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      u['nama'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      u['email'] ?? '-',
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      u['role'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

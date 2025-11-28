// lib/screens/page/pelanggan_screen.dart
import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';
import 'package:tempest_store/widgets/add_customer.dart';
import 'package:tempest_store/widgets/edit_customer.dart';
import 'package:tempest_store/screens/page/buy_history.dart';
import 'package:tempest_store/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganScreen extends StatefulWidget {
  const PelangganScreen({super.key});

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  static const Color topBg = Color(0xFF93B9E8);
  static const Color borderColor = Color(0xFF3A71A4);
  static const Color cardBg = Colors.white;
  static const double horizontalPadding = 12.0;

  String query = '';
  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;

  RealtimeChannel? _customerChannel; // ← FIXED (RealtimeChannel yang benar)

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    _setupRealtime(); // realtime listener
  }

  // REALTIME LISTENER
  void _setupRealtime() {
    _customerChannel = Supabase.instance.client
        .channel('public:kasir_pelanggan') // channel ID
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'kasir_pelanggan',
        callback: (_) => fetchCustomers(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'kasir_penjualan',
        callback: (_) => fetchCustomers(),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _customerChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> fetchCustomers() async {
    setState(() => isLoading = true);
    try {
      final service = SupabaseService();
      final pelangganList = await service.getPelanggan();

      // Hitung total transaksi per pelanggan
      final res = await SupabaseService.client
          .from('kasir_penjualan')
          .select('pelangganid');

      final penjualanData = res as List<dynamic>? ?? [];
      final Map<int, int> totalTransaksiMap = {};

      for (var p in penjualanData) {
        final id = p['pelangganid'] as int?;
        if (id != null) {
          totalTransaksiMap[id] = (totalTransaksiMap[id] ?? 0) + 1;
        }
      }

      final merged = pelangganList.map((c) {
        final id = c['pelangganid'] as int?;
        return {
          'namapelanggan': c['namapelanggan']?.toString() ?? '-',
          'email': c['email']?.toString() ?? '-',
          'alamat': c['alamat']?.toString() ?? '-',
          'nomortelepon': c['nomortelepon']?.toString() ?? '-',
          'created_at': c['created_at']?.toString() ?? '-',
          'totalTransaksi': id != null ? (totalTransaksiMap[id] ?? 0) : 0,
          'pelangganid': id,
        };
      }).toList();

      setState(() => customers = merged);
    } catch (e) {
      debugPrint('Error fetching pelanggan: $e');
    }
    setState(() => isLoading = false);
  }

  void _showAddCustomerDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const AddCustomerDialog(),
    );
    await fetchCustomers();
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) async {
    await showDialog(
      context: context,
      builder: (_) => EditCustomerDialog(customer: customer),
    );
    await fetchCustomers();
  }

  void _openBuyHistory(int? pelangganId) {
    if (pelangganId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyHistoryScreen(pelangganId: pelangganId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = customers.where((c) {
      final q = query.toLowerCase();
      if (q.isEmpty) return true;
      return c.values.any((v) => v.toString().toLowerCase().contains(q));
    }).toList();

    return AppShell(
      title: 'Manajemen Pelanggan',
      child: Container(
        color: topBg,
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildTitle(filtered.length),
                const SizedBox(height: 10),
                _buildActionButtons(),
                const SizedBox(height: 12),
                _buildSearchBox(),
                const SizedBox(height: 12),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCustomerList(filtered),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manajemen Pelanggan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          'Total ada $total pelanggan',
          style: const TextStyle(fontSize: 13, color: borderColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF91C4D9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Pelanggan', style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: _showAddCustomerDialog,
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Cari nama, email, telepon, atau alamat',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(List<Map<String, dynamic>> data) {
    const double rowHeight = 68;
    const int maxVisibleRows = 4;
    final double tableHeight = (data.length > maxVisibleRows ? maxVisibleRows : data.length) * rowHeight;

    final headers = [
      {'title': 'Nama', 'width': 200.0},
      {'title': 'Alamat', 'width': 200.0},
      {'title': 'Telepon', 'width': 120.0},
      {'title': 'Total Pembelian', 'width': 130.0},
      {'title': 'Bergabung', 'width': 120.0},
      {'title': 'Aksi', 'width': 80.0},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: Column(
            children: [
              Row(
                children: headers.map((h) {
                  final double width = h['width'] as double;
                  return Container(
                    width: width,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 2),
                      ),
                    ),
                    child: Text(
                      h['title'].toString(),
                      textAlign: h['title'] == 'Nama' ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(
                height: tableHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: data.map((c) {
                      return Row(
                        children: [
                          _buildCell(c['namapelanggan'].toString(), width: 200, isFirst: true, subText: c['email']),
                          _buildCell(c['alamat'] ?? '-', width: 200),
                          _buildCell(c['nomortelepon'] ?? '-', width: 120),
                          _buildCell(c['totalTransaksi'].toString(), width: 120),
                          _buildCell(c['created_at']?.toString().split('T').first ?? '-', width: 120),
                          _buildActionCell(c),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {required double width, bool isFirst = false, String? subText}) {
    return Container(
      width: width,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: isFirst
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                if (subText != null)
                  Text(subText, style: const TextStyle(fontSize: 13, color: borderColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            )
          : Center(child: Text(text, style: const TextStyle(fontSize: 14))),
    );
  }

  Widget _buildActionCell(Map<String, dynamic> c) {
    return Container(
      width: 80,
      height: 68,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              onPressed: c['pelangganid'] == null ? null : () => _openBuyHistory(c['pelangganid']),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showEditCustomerDialog(c),
            ),
          ),
        ],
      ),
    );
  }
}

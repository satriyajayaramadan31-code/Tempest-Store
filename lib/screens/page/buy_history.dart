// Updated BuyHistoryScreen with proper date formatting and full-width border
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:tempest_store/services/supabase_service.dart';

class BuyHistoryScreen extends StatefulWidget {
  final int pelangganId;

  const BuyHistoryScreen({super.key, required this.pelangganId});

  @override
  State<BuyHistoryScreen> createState() => _BuyHistoryScreenState();
}

class _BuyHistoryScreenState extends State<BuyHistoryScreen> {
  static const Color topBg = Color(0xFFF7F9FB);
  static const Color accent = Color(0xFF2F6EA8);
  static const Color borderColor = Color(0xFF91C4D9);

  bool isLoading = true;
  Map<String, dynamic> _customer = {};
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    try {
      await _fetchCustomer();
      await _fetchTransactions();
    } catch (e) {
      debugPrint("Error all: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String formatTanggal(dynamic rawDate) {
    if (rawDate == null) return '-';
    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();
      return DateFormat('dd/MM/yyyy, HH.mm.ss').format(date);
    } catch (_) {
      return rawDate.toString();
    }
  }

  Future<void> _fetchCustomer() async {
    final res = await SupabaseService.client
        .from('kasir_pelanggan')
        .select('namapelanggan, email')
        .eq('pelangganid', widget.pelangganId)
        .single();

    _customer = res is Map ? res : {};
  }

  Future<void> _fetchTransactions() async {
    try {
      final penjualanRes = await SupabaseService.client
          .from('kasir_penjualan')
          .select('penjualanid, totalharga, tanggalpenjualan')
          .eq('pelangganid', widget.pelangganId)
          .order('penjualanid', ascending: false);

      final penjualanData = penjualanRes is List ? penjualanRes : [];

      List<Map<String, dynamic>> txList = [];

      for (var p in penjualanData) {
        final idPenjualan = p['penjualanid'];

        final strukRes = await SupabaseService.client
            .from('kasir_struk')
            .select('kode_pengenalan, created_at')
            .eq('penjualanid', idPenjualan)
            .maybeSingle();

        final kodeStruk = strukRes?['kode_pengenalan'] ?? '-';
        final tanggalStruk = formatTanggal(
          strukRes?['created_at'] ?? p['tanggalpenjualan'],
        );

        final detailRes = await SupabaseService.client
            .from('kasir_detailpenjualan')
            .select('jumlahproduk, kasir_produk(namaproduk)')
            .eq('penjualanid', idPenjualan);

        final details = detailRes is List ? detailRes : [];

        final items = details.map((d) {
          final produk = d['kasir_produk'] as Map<String, dynamic>? ?? {};
          return '${d['jumlahproduk']}x ${produk['namaproduk'] ?? '-'}';
        }).toList();

        txList.add({
          'id': kodeStruk,
          'date': tanggalStruk,
          'total': 'Rp ${p['totalharga'] ?? 0}',
          'items': items,
        });
      }

      _transactions = txList;
    } catch (e) {
      debugPrint('Error trans: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: topBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(child: _buildContent(context)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Riwayat Pembelian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, size: 22),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          height: 1.5,
          color: accent,
        ),

        const SizedBox(height: 16),

        Text(
          _customer['namapelanggan'] ?? '-',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF343A4A)),
        ),
        const SizedBox(height: 4),
        Text(
          _customer['email'] ?? '-',
          style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        Text(
          'Total ada ${_transactions.length} transaksi',
          style: const TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 25),

        ..._transactions.map(_buildTransactionBlock),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTransactionBlock(Map<String, dynamic> tx) {
    final items = List<String>.from(tx['items'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tx['id'],
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: accent),
              ),
            ),
            Text(
              tx['total'],
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: accent),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          tx['date'],
          style: const TextStyle(color: Color(0xFF91C4D9), fontSize: 12),
        ),

        const SizedBox(height: 8),
        const Divider(height: 12, thickness: 1, color: accent),
        const SizedBox(height: 8),

        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                i,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )),

        const SizedBox(height: 22),
      ],
    );
  }
}
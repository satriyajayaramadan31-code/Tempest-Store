// lib/screens/page/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tempest_store/services/supabase_service.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _svc = SupabaseService();

  bool _loading = true;

  double _todaySales = 0;
  int _todayTransactions = 0;
  int _totalStockCount = 0;
  int _activeCustomers = 0;
  int _lowStockCount = 0;

  // 7 hari (Mon..Sun) index 0..6
  List<double> _weeklySales = List<double>.filled(7, 0);

  // recent tx (5 latest)
  final List<Map<String, dynamic>> _recentTx = [];

  final List<Map<String, dynamic>> _lowStockProducts = [];

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  StreamSubscription<dynamic>? _produkSub;
  StreamSubscription<dynamic>? _penjualanSub;

  Timer? _produkDebounce;
  Timer? _penjualanDebounce;

  @override
  void initState() {
    super.initState();
    _startRealtime();
    _loadDashboard();
  }

  @override
  void dispose() {
    _produkSub?.cancel();
    _penjualanSub?.cancel();
    _produkDebounce?.cancel();
    _penjualanDebounce?.cancel();
    super.dispose();
  }

  void _startRealtime() {
    try {
      // produk: only update produk-related UI (stok, low-stock) to avoid UI thrash
      _produkSub = SupabaseService.client
          .from('kasir_produk')
          .stream(primaryKey: ['produkid'])
          .listen((_) {
        _produkDebounce?.cancel();
        _produkDebounce = Timer(const Duration(milliseconds: 400), () {
          if (mounted) _loadProdukOnly();
        });
      }, onError: (err) {
        debugPrint('produk realtime error: $err');
      });

      // penjualan: update penjualan metrics + recent transactions
      _penjualanSub = SupabaseService.client
          .from('kasir_penjualan')
          .stream(primaryKey: ['penjualanid'])
          .listen((_) {
        _penjualanDebounce?.cancel();
        _penjualanDebounce = Timer(const Duration(milliseconds: 400), () {
          if (mounted) _loadPenjualanLatestAndMetrics();
        });
      }, onError: (err) {
        debugPrint('penjualan realtime error: $err');
      });
    } catch (e, st) {
      debugPrint('startRealtime exception: $e\n$st');
    }
  }

  /// Full initial load (produk, pelanggan, penjualan)
  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    _recentTx.clear();
    _lowStockProducts.clear();
    _lowStockCount = 0;
    _weeklySales = List<double>.filled(7, 0);
    _totalStockCount = 0;

    try {
      final produk = await _svc.getProduk();
      final pelanggan = await _svc.getPelanggan();
      final penjualan = await _svc.getPenjualan();

      _activeCustomers = pelanggan.length;

      _processProdukList(produk);
      _processPenjualanList(penjualan, fullList: true);

      // build recentTx from penjualan (top 5 by penjualanid desc)
      final sorted = List<Map<String, dynamic>>.from(penjualan);
      sorted.sort((a, b) {
        final ai = a['penjualanid'] ?? 0;
        final bi = b['penjualanid'] ?? 0;
        return (bi as num).compareTo(ai as num);
      });

      _recentTx
        ..clear()
        ..addAll(sorted.take(5).map((row) {
          final totalRaw = row['totalharga'] ?? row['total'] ?? 0;
          final total = (totalRaw is num) ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0;
          return {
            'kode': row['penjualanid'] != null ? 'TRX-${row['penjualanid'].toString().padLeft(6, '0')}' : 'TRX-unknown',
            'nama': (row['kasir_pelanggan'] != null && row['kasir_pelanggan']['namapelanggan'] != null)
                ? row['kasir_pelanggan']['namapelanggan']
                : (row['namapelanggan'] ?? 'Pelanggan'),
            'total': total,
            'method': row['payment_method'] ?? 'Cash',
          };
        }));
    } catch (e, st) {
      debugPrint('Error load dashboard: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Partial updater: reload produk-only (stok/low-stock) — called from produk realtime
  Future<void> _loadProdukOnly() async {
    try {
      final produk = await _svc.getProduk();
      _processProdukList(produk);
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('Error loadProdukOnly: $e\n$st');
    }
  }

  /// Partial updater: reload penjualan metrics + latest 5 tx — called from penjualan realtime
  Future<void> _loadPenjualanLatestAndMetrics() async {
    try {
      final penjualan = await _svc.getPenjualan();

      _processPenjualanList(penjualan, fullList: true);

      // build 5 latest transactions
      final sorted = List<Map<String, dynamic>>.from(penjualan);
      sorted.sort((a, b) {
        final ai = a['penjualanid'] ?? 0;
        final bi = b['penjualanid'] ?? 0;
        return (bi as num).compareTo(ai as num);
      });

      _recentTx
        ..clear()
        ..addAll(sorted.take(5).map((row) {
          final totalRaw = row['totalharga'] ?? row['total'] ?? 0;
          final total = (totalRaw is num) ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0;
          return {
            'kode': row['penjualanid'] != null ? 'TRX-${row['penjualanid'].toString().padLeft(6, '0')}' : 'TRX-unknown',
            'nama': (row['kasir_pelanggan'] != null && row['kasir_pelanggan']['namapelanggan'] != null)
                ? row['kasir_pelanggan']['namapelanggan']
                : (row['namapelanggan'] ?? 'Pelanggan'),
            'total': total,
            'method': row['payment_method'] ?? 'Cash',
          };
        }));

      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('Error loadPenjualanLatestAndMetrics: $e\n$st');
    }
  }

  void _processProdukList(List<Map<String, dynamic>> produk) {
    int totalStockCount = 0;
    _lowStockProducts.clear();
    _lowStockCount = 0;

    for (final p in produk) {
      final stokRaw = p['stok'] ?? 0;
      final minimumRaw = p['minimum'] ?? 0;

      final stok = (stokRaw is int) ? stokRaw : int.tryParse(stokRaw.toString()) ?? 0;
      final minimum = (minimumRaw is int) ? minimumRaw : int.tryParse(minimumRaw.toString()) ?? 0;

      totalStockCount += stok;

      if (minimum > 0 && stok <= minimum) {
        _lowStockCount++;
        _lowStockProducts.add({
          'produkid': p['produkid'],
          'namaproduk': p['namaproduk'],
          'stok': stok,
          'minimum': minimum,
        });
      }
    }

    _totalStockCount = totalStockCount;
  }

  void _processPenjualanList(List<Map<String, dynamic>> penjualan, {required bool fullList}) {
    _weeklySales = List<double>.filled(7, 0);
    _todaySales = 0;
    _todayTransactions = 0;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    for (final row in penjualan) {
      final totalRaw = row['totalharga'] ?? row['total'] ?? 0;
      final total = (totalRaw is num) ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0;

      DateTime? dt;
      try {
        final s = row['tanggalpenjualan']?.toString();
        if (s != null && s.isNotEmpty) dt = DateTime.parse(s);
      } catch (_) {
        dt = null;
      }

      if (dt != null) {
        final rowDateStr = DateFormat('yyyy-MM-dd').format(dt);
        if (rowDateStr == todayStr) {
          _todaySales += total;
          _todayTransactions++;
        }
        final idx = (dt.weekday - 1).clamp(0, 6);
        _weeklySales[idx] = _weeklySales[idx] + total;
      }
    }
  }

  void _goToProducts() => Navigator.pushReplacementNamed(context, '/produk');
  void _goToAllTransactions() => Navigator.pushReplacementNamed(context, '/laporan');

  Widget _buildWeeklyChart(double displayMax) {
    // safe horizontal interval (must not be zero)
    final double maxVal = (_weeklySales.isNotEmpty) ? _weeklySales.reduce((a, b) => a > b ? a : b) : 0;
    double horizontalInterval = (maxVal <= 0) ? 1.0 : (maxVal / 5.0);
    if (horizontalInterval <= 0) horizontalInterval = 1.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Penjualan Mingguan', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: displayMax,
                  gridData: FlGridData(show: true, drawHorizontalLine: true, horizontalInterval: horizontalInterval),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final val = (_weeklySales.length > i) ? _weeklySales[i] : 0.0;
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          color: i % 2 == 0 ? Colors.blue[800]! : Colors.blue[300]!,
                        )
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                          final idx = value.toInt().clamp(0, 6);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(days[idx], style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final val = value.toInt();
                          final label = val >= 1000000 ? '${(val / 1000000).round()}M' : val.toString();
                          return Padding(padding: const EdgeInsets.only(right: 6), child: Text(label, style: const TextStyle(fontSize: 10)));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String title, required String value, VoidCallback? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3A71A4))),
        subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3A71A4))),
        trailing: Icon(icon, size: 30, color: Color(0xFF3A71A4)),
      ),
    );
  }

  Widget _buildLowStockCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 30, color: Color(0xFF3A71A4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peringatan Stok Rendah', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3F598C))),
                  const SizedBox(height: 6),
                  Text(
                    _lowStockCount > 0 ? '$_lowStockCount produk stok rendah' : 'Semua stok aman',
                    style: const TextStyle(color: Color(0xFF3A71A4)),
                  ),
                  if (_lowStockProducts.isNotEmpty) const SizedBox(height: 8),
                  if (_lowStockProducts.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _lowStockProducts.take(3).map((p) => Chip(label: Text('${p['namaproduk']} (${p['stok']}/${p['minimum']})'))).toList(),
                    ),
                ],
              ),
            ),
            ElevatedButton(onPressed: _goToProducts, 
            child: const Text(
              'Lihat Produk', 
              style: TextStyle(color: Color(0xFF3A71A4))
            ),
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
                side: BorderSide(color: Color(0xFF3A71A4), width: 1.5),
              ),
            ),)
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('Transaksi Terbaru', 
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A71A4)
                      )
                    )
                  ),
                TextButton(onPressed: _goToAllTransactions, 
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                const Text(
                  'Lihat Semua', 
                  style: TextStyle(color: Color(0xFF3A71A4),
                    )
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_right_alt, size: 30, color: Color(0xFF3A71A4),)
                  ]
                )
                )
              ],
            ),
            const SizedBox(height: 8),
            if (_recentTx.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada transaksi', style: TextStyle(color: Color(0xFF3A71A4))))
            else
              Column(
                children: _recentTx.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx['kode'] ?? 'TRX-unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A71A4))),
                              const SizedBox(height: 4),
                              Text(tx['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF91C4D9))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_currency.format(tx['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A71A4))),
                            const SizedBox(height: 4),
                            Text(tx['method'] ?? '', style: const TextStyle(color: Color(0xFF91C4D9))),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFF93B9E8);
    final maxVal = _weeklySales.isNotEmpty ? _weeklySales.reduce((a, b) => a > b ? a : b) : 0.0;
    final displayMax = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return AppShell(
      title: 'Dashboard',
      child: Container(
        color: background,
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildWeeklyChart(displayMax),
                      const SizedBox(height: 12),
                      _buildMetricCard(icon: Icons.attach_money_rounded, title: 'Penjualan Hari Ini', value: _currency.format(_todaySales)),
                      const SizedBox(height: 8),
                      _buildMetricCard(icon: Icons.receipt_long_rounded, title: 'Transaksi Hari Ini', value: '$_todayTransactions'),
                      const SizedBox(height: 8),
                      _buildMetricCard(icon: Icons.inventory_2_outlined, title: 'Total Stok Produk', value: '$_totalStockCount', onTap: _goToProducts),
                      const SizedBox(height: 8),
                      _buildMetricCard(icon: Icons.people_alt_rounded, title: 'Pelanggan Aktif', value: '$_activeCustomers'),
                      const SizedBox(height: 12),
                      _buildLowStockCard(),
                      const SizedBox(height: 12),
                      _buildRecentTransactions(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

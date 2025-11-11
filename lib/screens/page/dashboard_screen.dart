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

  // Metrics
  double _todaySales = 0;
  int _todayTransactions = 0;
  int _totalStockCount = 0; // <-- jumlah unit stok (total kuantitas)
  int _activeCustomers = 0;
  int _lowStockCount = 0;

  // Chart: 7 data points for Mon..Sun
  List<double> _weeklySales = List<double>.filled(7, 0);

  // Recent transactions
  final List<Map<String, dynamic>> _recentTx = [];

  // Optional: daftar produk stok rendah (untuk detail nanti)
  final List<Map<String, dynamic>> _lowStockProducts = [];

  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    // reset containers
    _recentTx.clear();
    _lowStockProducts.clear();
    _lowStockCount = 0;
    _weeklySales = List<double>.filled(7, 0);
    _totalStockCount = 0; // reset jumlah stok

    try {
      final penjualanRaw = await _svc.getPenjualan(); // List<Map>
      final produkRaw = await _svc.getProduk();
      final pelangganRaw = await _svc.getPelanggan();

      // Ensure types
      final List<Map<String, dynamic>> penjualan = List<Map<String, dynamic>>.from(penjualanRaw);
      final List<Map<String, dynamic>> produk = List<Map<String, dynamic>>.from(produkRaw);
      final List<Map<String, dynamic>> pelanggan = List<Map<String, dynamic>>.from(pelangganRaw);

      // Active customers
      _activeCustomers = pelanggan.length;

      // Total stock count & low stock count (menggunakan kolom 'minimum' jika ada)
      int totalStockCount = 0;
      for (final p in produk) {
        // stok dan harga bisa berupa String atau num
        final stokRaw = p['stok'] ?? 0;
        final minimumRaw = p['minimum'] ?? 0; // <-- pakai kolom minimum

        final intStok = (stokRaw is int) ? stokRaw : int.tryParse(stokRaw.toString()) ?? 0;
        final intMinimum = (minimumRaw is int) ? minimumRaw : int.tryParse(minimumRaw.toString()) ?? 0;

        // HITUNG jumlah unit stok (bukan nilai)
        totalStockCount += intStok;

        // Hanya hitung sebagai "stok rendah" jika minimum > 0
        if (intMinimum > 0 && intStok <= intMinimum) {
          _lowStockCount += 1;
          _lowStockProducts.add({
            'produkid': p['produkid'],
            'namaproduk': p['namaproduk'],
            'stok': intStok,
            'minimum': intMinimum,
          });
        }
      }
      _totalStockCount = totalStockCount;

      // Aggregate penjualan
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      penjualan.sort((a, b) {
        final da = a['tanggalpenjualan']?.toString() ?? '';
        final db = b['tanggalpenjualan']?.toString() ?? '';
        try {
          final dA = DateTime.parse(da);
          final dB = DateTime.parse(db);
          return dB.compareTo(dA);
        } catch (_) {
          return 0;
        }
      });

      double todaySum = 0;
      int todayCount = 0;
      int addedRecent = 0;

      for (final row in penjualan) {
        final totalRaw = row['totalharga'] ?? row['total'] ?? 0;
        final doubleTotal = (totalRaw is num) ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0;

        DateTime? dt;
        try {
          final t = row['tanggalpenjualan']?.toString();
          if (t != null && t.isNotEmpty) dt = DateTime.parse(t);
        } catch (_) {
          dt = null;
        }

        if (dt != null) {
          final rowDateStr = DateFormat('yyyy-MM-dd').format(dt);
          if (rowDateStr == todayStr) {
            todaySum += doubleTotal;
            todayCount += 1;
          }
          final idx = (dt.weekday - 1).clamp(0, 6);
          _weeklySales[idx] = _weeklySales[idx] + doubleTotal;
        }

        if (addedRecent < 5) {
          _recentTx.add({
            'kode': row['penjualanid'] != null ? 'TRX-${row['penjualanid'].toString().padLeft(6, '0')}' : 'TRX-unknown',
            'nama': (row['kasir_pelanggan'] != null && row['kasir_pelanggan']['namapelanggan'] != null)
                ? row['kasir_pelanggan']['namapelanggan']
                : (row['namapelanggan'] ?? 'Pelanggan'),
            'total': doubleTotal,
            'method': row['payment_method'] ?? 'Cash',
          });
          addedRecent++;
        }
      }

      _todaySales = todaySum;
      _todayTransactions = todayCount;
    } catch (e) {
      debugPrint('Error load dashboard: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToProducts() {
    Navigator.pushReplacementNamed(context, '/produk');
  }

  void _goToAllTransactions() {
    Navigator.pushReplacementNamed(context, '/laporan');
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Icon(icon, color: Colors.blue[700]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue[800])),
        trailing: onTap != null ? Icon(Icons.chevron_right, color: Colors.grey[400]) : null,
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          color: color,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFF93B9E8);

    final body = RefreshIndicator(
      onRefresh: _loadDashboard,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Chart card
                  Card(
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
                                maxY: (_weeklySales.isNotEmpty ? _weeklySales.reduce((a, b) => a > b ? a : b) : 1) * 1.2,
                                titlesData: FlTitlesData(
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
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                                        final idx = value.toInt().clamp(0, 6);
                                        return Text(days[idx], style: const TextStyle(fontSize: 11));
                                      },
                                      reservedSize: 28,
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(show: true, drawHorizontalLine: true, horizontalInterval: _weeklySales.isNotEmpty ? (_weeklySales.reduce((a, b) => a > b ? a : b) / 5) : 1),
                                barGroups: List.generate(
                                  7,
                                  (i) {
                                    final color = i % 2 == 0 ? Colors.blue[800]! : Colors.blue[300]!;
                                    return _makeBarGroup(i, _weeklySales[i], color);
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Metric cards
                  _buildMetricCard(icon: Icons.attach_money_rounded, title: 'Penjualan Hari Ini', value: _currency.format(_todaySales), onTap: null),
                  const SizedBox(height: 8),
                  _buildMetricCard(icon: Icons.receipt_long_rounded, title: 'Transaksi Hari Ini', value: _todayTransactions.toString(), onTap: null),
                  const SizedBox(height: 8),
                  _buildMetricCard(icon: Icons.inventory_2_outlined, title: 'Total Stok Produk', value: _totalStockCount.toString(), onTap: _goToProducts),
                  const SizedBox(height: 8),
                  _buildMetricCard(icon: Icons.people_alt_rounded, title: 'Pelanggan Aktif', value: _activeCustomers.toString(), onTap: null),

                  const SizedBox(height: 12),

                  // Low stock warning
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 28, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Peringatan Stok Rendah', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                  _lowStockCount > 0
                                      ? '$_lowStockCount produk memiliki stok di bawah batas minimum'
                                      : 'Semua produk memiliki stok aman',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                if (_lowStockProducts.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  // tampilkan nama produk yang stok rendah (maks 3)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: _lowStockProducts.take(3).map((p) {
                                      return Chip(
                                        label: Text('${p['namaproduk']} (${p['stok']}/${p['minimum']})'),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ElevatedButton(onPressed: _goToProducts, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Lihat Produk'))
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Recent transactions
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Transaksi Terbaru', style: TextStyle(fontWeight: FontWeight.w700))),
                              TextButton(onPressed: _goToAllTransactions, child: const Text('Lihat Semua'))
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_recentTx.isEmpty)
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada transaksi'))
                          else
                            Column(children: _recentTx.map((tx) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(tx['kode'] ?? 'TRX-unknown', style: const TextStyle(fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(tx['nama'] ?? '-', style: const TextStyle(color: Colors.black54)),
                                      ]),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(_currency.format(tx['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text(tx['method'] ?? '', style: const TextStyle(color: Colors.black54)),
                                    ]),
                                  ],
                                ),
                              );
                            }).toList()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
    );

    // Wrap with AppShell to get responsive sidebar / appbar
    return AppShell(
      title: 'Dashboard',
      child: Container(
        color: background,
        child: body,
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

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

  final List<Map<String, String>> customers = List.generate(20, (i) {
    return {
      'name': 'Adi setya pratama',
      'email': 'jadiapa2254@gmail.com',
      'phone': '082255423325',
      'address': 'Jl. Jadi Santoso RT 2. RW 12',
      'total': '10 Transaksi',
      'joined': '05/10/2023',
    };
  });

  @override
  Widget build(BuildContext context) {
    final filtered = customers.where((c) {
      final q = query.toLowerCase();
      if (q.isEmpty) return true;
      return c.values.any((v) => v.toLowerCase().contains(q));
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
                // Expanded agar scroll vertical untuk list
                Expanded(
                  child: _buildCustomerList(filtered),
                ),
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
        const Text('Manajemen Pelanggan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
        const SizedBox(height: 4),
        Text('Total ada $total pelanggan',
            style: const TextStyle(fontSize: 13, color: borderColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF91C4D9),
              foregroundColor: Colors.white,
              side: const BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Pelanggan', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () {},
          ),
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

Widget _buildCustomerList(List<Map<String, String>> data) {
  // column fixed widths
  final colWidths = <double>[200, 200, 120, 120, 120, 80];
  final totalCols = colWidths.reduce((a, b) => a + b);
  const headerHorizontalPadding = 12.0 * 2; // left + right in header Container
  final minTableWidth = totalCols + headerHorizontalPadding;

  const rowHeight = 68.0;
  const headerHeight = 56.0;
  final visibleRows = math.min(10, data.length);

  return Container(
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        // ensure min width is at least the sum of column widths + paddings
        constraints: BoxConstraints(minWidth: minTableWidth),
        child: LayoutBuilder(builder: (context, constraints) {
          // constraints.maxWidth may be Infinity when inside horizontal SingleChildScrollView.
          // Use minTableWidth when maxWidth is unbounded.
          final tableWidth = constraints.maxWidth.isFinite
              ? math.max(minTableWidth, constraints.maxWidth)
              : minTableWidth;

          // limit table height to available area but allow vertical scrolling inside
          final maxAvailableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.5;
          final computedHeight = math.min(maxAvailableHeight, headerHeight + visibleRows * rowHeight);

          return SizedBox(
            width: tableWidth,
            height: computedHeight,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(bottom: BorderSide(color: borderColor, width: 2.8)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: colWidths[0], child: const Text('Nama', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: colWidths[1], child: const Text('Email', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: colWidths[2], child: const Text('Telepon', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: colWidths[3], child: const Text('Total Transaksi', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: colWidths[4], child: const Text('Bergabung', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: colWidths[5], child: const Text('Aksi', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

                // Rows: ListView handles vertical scrolling
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: data.length,
                    separatorBuilder: (context, index) => Divider(color: borderColor, thickness: 2, height: 2),
                    itemBuilder: (context, index) {
                      final c = data[index];
                      return SizedBox(
                        height: rowHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: colWidths[0],
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(c['address']!, style: const TextStyle(color: Color(0xFF91C4D9), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: colWidths[1], child: Center(child: Text(c['email']!, style: const TextStyle(fontSize: 16)))),
                            SizedBox(width: colWidths[2], child: Center(child: Text(c['phone']!, style: const TextStyle(fontSize: 16)))),
                            SizedBox(width: colWidths[3], child: Center(child: Text(c['total']!, style: const TextStyle(fontSize: 16)))),
                            SizedBox(width: colWidths[4], child: Center(child: Text(c['joined']!, style: const TextStyle(fontSize: 16)))),
                            SizedBox(
                              width: colWidths[5],
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                                      onPressed: () {},
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
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );
}
}
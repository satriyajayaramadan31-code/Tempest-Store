import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  static const Color topBg = Color(0xFF93B9E8);
  static const Color borderColor = Color(0xFF3A71A4);
  static const Color cardBg = Color(0xFFF7FCFC);
  static const double horizontalPadding = 12.0;

  // Sample data
  List<Map<String, String>> get _productRows => List.generate(
        20,
        (i) => {
          'nama': 'Kopi Arabic Premium',
          'terjual': (300).toString(),
          'pendapatan': 'Rp 13.500.000',
        },
      );

  List<Map<String, String>> get _trxRows => List.generate(
        20,
        (i) => {
          'no': 'TRX-20241013-${i.toString().padLeft(3, '0')}',
          'pelanggan': 'Pelanggan $i',
          'item': (300 + i).toString(),
        },
      );

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Laporan',
      child: Container(
        color: topBg,
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 8),
                  _buildActionButtonsRow(context),
                  const SizedBox(height: 12),
                  _buildFilterBox(),
                  const SizedBox(height: 12),
                  _buildStatCard(title: 'Total Penjualan', value: 'Rp 7.000.000.000'),
                  const SizedBox(height: 10),
                  _buildStatCard(title: 'Total Transaksi', value: '1.400.000'),
                  const SizedBox(height: 10),
                  _buildProfitCard(),
                  const SizedBox(height: 12),
                  _buildProductListCard(context),
                  const SizedBox(height: 12),
                  _buildTransactionListCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================================================
  // TITLE
  // ======================================================
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Laporan Penjualan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          'Analisis dan Statistik Penjualan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF3A71A4),
          ),
        ),
      ],
    );
  }

  // ======================================================
  // ACTION BUTTONS
  // ======================================================
  Widget _buildActionButtonsRow(BuildContext context) {
    Widget smallButton({required IconData icon, required String label}) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Row(
      children: [
        smallButton(icon: Icons.insert_drive_file_outlined, label: 'Laporan'),
        smallButton(icon: Icons.upload_outlined, label: 'Export'),
        smallButton(icon: Icons.print_outlined, label: 'Struk'),
      ],
    );
  }

  // ======================================================
  // FILTER BOX
  // ======================================================
  Widget _buildFilterBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Column(
        children: [
          _buildFilterField(label: 'Periode:', hint: 'Pilih Periode...'),
          const SizedBox(height: 8),
          _buildFilterField(label: 'Produk:', hint: 'Pilih Produk...'),
          const SizedBox(height: 8),
          _buildFilterField(label: 'Pelanggan:', hint: 'Pilih Pelanggan...'),
        ],
      ),
    );
  }

  Widget _buildFilterField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            hint,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  // ======================================================
  // STATIC CARDS
  // ======================================================
  Widget _buildStatCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: borderColor)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: borderColor)),
        ],
      ),
    );
  }

  Widget _buildProfitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Laba', style: TextStyle(fontWeight: FontWeight.w800, color: borderColor)),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.arrow_upward, color: Colors.green),
              SizedBox(width: 6),
              Text(
                'Rp 500.000.000',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: borderColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================================================
  // PRODUCT LIST
  // ======================================================
// ======================================================
// PRODUCT LIST
// ======================================================
Widget _buildProductListCard(BuildContext context) {
  final double rowHeight = 56; // default DataRow height
  final int maxVisibleRows = 5;
  final tableHeight = (_productRows.length > maxVisibleRows
          ? maxVisibleRows
          : _productRows.length) *
      rowHeight + 56; // + headingRow height

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor, width: 1.6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daftar Produk',
            style: TextStyle(fontWeight: FontWeight.w800, color: borderColor)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: borderColor, // garis horizontal antar row
              ),
              child: SizedBox(
                height: tableHeight.toDouble(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    dividerThickness: 1.6,
                    headingRowColor: MaterialStateProperty.all(cardBg),
                    headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: borderColor),
                    dataTextStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                    columns: const [
                      DataColumn(label: Text('Nama Produk')),
                      DataColumn(label: Text('Terjual'), numeric: true),
                      DataColumn(label: Text('Pendapatan'), numeric: true),
                    ],
                    rows: _productRows
                        .map((row) => DataRow(
                              color: MaterialStateProperty.all(cardBg),
                              cells: [
                                DataCell(Text(row['nama']!)),
                                DataCell(Text(row['terjual']!)),
                                DataCell(Text(row['pendapatan']!)),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ======================================================
// TRANSACTION LIST
// ======================================================
Widget _buildTransactionListCard(BuildContext context) {
  final double rowHeight = 56; // default DataRow height
  final int maxVisibleRows = 5;
  final tableHeight = (_trxRows.length > maxVisibleRows
          ? maxVisibleRows
          : _trxRows.length) *
      rowHeight + 56; // + headingRow height

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor, width: 1.6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Transaksi',
          style: TextStyle(fontWeight: FontWeight.w800, color: borderColor),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: borderColor, // warna garis horizontal antar row
              ),
              child: SizedBox(
                height: tableHeight.toDouble(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    dividerThickness: 1.6,
                    headingRowColor: MaterialStateProperty.all(cardBg),
                    headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: borderColor),
                    dataTextStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                    columns: const [
                      DataColumn(label: Text('No. Transaksi')),
                      DataColumn(label: Text('Pelanggan')),
                      DataColumn(label: Text('Item'), numeric: true),
                    ],
                    rows: _trxRows
                        .map(
                          (row) => DataRow(
                            color: MaterialStateProperty.all(cardBg),
                            cells: [
                              DataCell(Text(row['no']!)),
                              DataCell(Text(row['pelanggan']!)),
                              DataCell(Text(row['item']!)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
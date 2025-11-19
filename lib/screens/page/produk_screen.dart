import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  static const Color topBg = Color(0xFF93B9E8);
  static const Color borderColor = Color(0xFF3A71A4);
  static const Color cardBg = Colors.white; // List background putih
  static const double horizontalPadding = 12.0;

  String query = '';

  final List<Map<String, dynamic>> products = [
    {'name': 'Kopi Arabic Premium', 'sku': 'KOP-001', 'category': 'Minuman', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
    {'name': 'Cupcake', 'sku': 'CUP-001', 'category': 'Roti & Kue', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
    {'name': 'Cheese Bread', 'sku': 'BRD-003', 'category': 'Roti & Kue', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
    {'name': 'Potato Chips', 'sku': 'SNK-005', 'category': 'Snack', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
    {'name': 'Donut', 'sku': 'BCK-021', 'category': 'Roti & Kue', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
    {'name': 'Jus Jeruk Fresh', 'sku': 'JJK-014', 'category': 'Minuman', 'price': 'Rp 5.000', 'stock': 8, 'status': 'Stok Rendah'},
    {'name': 'Chocolate Drink', 'sku': 'COC-002', 'category': 'Minuman', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
    {'name': 'Mineral Water', 'sku': 'MWN-025', 'category': 'Minuman', 'price': 'Rp 45.000', 'stock': 521, 'status': 'Normal'},
  ];

  // Getter untuk produk stok rendah
  List<Map<String, dynamic>> get lowStock =>
      products.where((p) => (p['stock'] as int) < 10).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) {
      final q = query.toLowerCase();
      if (q.isEmpty) return true;
      return (p['name'] as String).toLowerCase().contains(q) ||
          (p['sku'] as String).toLowerCase().contains(q) ||
          (p['category'] as String).toLowerCase().contains(q);
    }).toList();

    return AppShell(
      title: 'Manajemen Produk',
      child: Container(
        color: topBg,
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildTitle(),
                  const SizedBox(height: 10),
                  _buildActionButtons(),
                  const SizedBox(height: 12),
                  if (lowStock.isNotEmpty) _buildLowStockCard(lowStock),
                  const SizedBox(height: 10),
                  _buildSearchBox(),
                  const SizedBox(height: 12),
                  _buildProductList(filtered),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Manajemen Produk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
        SizedBox(height: 4),
        Text('Total ada 300 produk', style: TextStyle(fontSize: 13, color: borderColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons() {
    Widget button(String label, IconData icon) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF91C4D9),
            foregroundColor: Colors.white,
            side: const BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () {},
        ),
      );
    }

    return Row(
      children: [
        button('Tambah Produk', Icons.add),
        button('Tambah Stok', Icons.add),
      ],
    );
  }

  Widget _buildLowStockCard(List<Map<String, dynamic>> lowStock) {
    final item = lowStock.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 Produk Memiliki Stok Rendah', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                const SizedBox(height: 4),
                Text(item['name'], style: const TextStyle(color: borderColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
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
                hintText: 'Cari Produk, SKU, atau Kategori',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> data) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(bottom: BorderSide(color: borderColor, width: 2.8)),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 200, child: Text('Nama Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 100, child: Text('SKU', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 120, child: Text('Kategori', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 100, child: Text('Harga', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 60, child: Text('Stok', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text('Aksi', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // Rows
            ...data.map((p) {
              final isLow = (p['stock'] as int) < 10;
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 2)), // pembatas antar baris
                ),
                child: Row(
                  children: [
                    SizedBox(width: 200, child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    SizedBox(width: 100, child: Text(p['sku'], textAlign: TextAlign.center)),
                    SizedBox(width: 120, child: Text(p['category'], textAlign: TextAlign.center)),
                    SizedBox(width: 100, child: Text(p['price'], textAlign: TextAlign.center)),
                    SizedBox(width: 60, child: Text('${p['stock']}', textAlign: TextAlign.center)),
                    SizedBox(
                      width: 100,
                      child: Text(
                        p['status'],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: isLow ? Colors.orange : Colors.black),
                      ),
                    ),
                    SizedBox(
                      width: 80,
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
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () {},
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

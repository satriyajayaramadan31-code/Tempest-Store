import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  static const Color topBg = Color(0xFF93B9E8);
  static const Color borderColor = Color(0xFF3A71A4);
  static const Color chipSelected = Color(0xFFD8EEF9);

  String paymentMethod = '';
  int discount = 0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Kasir',
      child: Container(
        color: topBg,
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBox(context),
                  const SizedBox(height: 8),
                  _buildCategoryChips(),
                  const SizedBox(height: 12),
                  _buildProductCard(),
                  const SizedBox(height: 12),
                  _buildCartBox(),
                  const SizedBox(height: 12),
                  _buildSummary(),
                  const SizedBox(height: 18),
                  _buildPayButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.9), width: 2),
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari Produk atau SKU',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = ['Semua', 'Minuman', 'Roti & Kue', 'Snack'];
    return Row(
      children: chips.map((c) {
        final isSelected = c == 'Semua';
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? borderColor : Colors.white, // 'Semua' biru, lainnya putih
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.5), // semua border sama
            ),
            child: Text(
              c,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : borderColor, // teks 'Semua' putih, lainnya biru
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildProductCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.8),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              border: Border.all(color: borderColor.withOpacity(1.0)),
            ),
            child: Image.asset('kopi.jpeg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kopi Arabia Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: borderColor, // ganti sesuai warna yang diinginkan
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'KOP-001 • Stok: 47',
                  style: TextStyle(
                    fontSize: 12, 
                    color: borderColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Rp 45.000',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: borderColor, 
              fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
              bottom: BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Keranjang', style: TextStyle(fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                decoration: BoxDecoration(
                  color: chipSelected,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: const Text(
                  '1 Item',
                  style: TextStyle(fontSize: 10, color: borderColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 30,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
            child: const Text(
              'Pembelian...',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: const Text(
            'Keranjang Kosong',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w600, color: borderColor)),
              Text('Rp 0.000', style: TextStyle(fontWeight: FontWeight.w700, color: borderColor)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Text('Diskon Total', style: TextStyle(fontWeight: FontWeight.w600, color: borderColor))),
            SizedBox(
              width: 84,
              height: 20,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  hintText: '0',
                ),
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 0;
                  setState(() => discount = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black)),
              Text('Rp 0.000', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: borderColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600, color: borderColor)),
        ),
        Center(
          child: GestureDetector(
            onTap: () => _showPaymentPicker(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: Text(
                paymentMethod.isEmpty ? 'Pilih Metode Pembayaran' : paymentMethod,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF91C4D9),
          foregroundColor: Colors.white,
          side: const BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 2,
        ),
        child: const Text(
          'Bayar',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }

  void _showPaymentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final methods = ['Tunai', 'Debit', 'QRIS'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: methods.map((m) {
              return ListTile(
                title: Text(m),
                onTap: () {
                  setState(() => paymentMethod = m);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

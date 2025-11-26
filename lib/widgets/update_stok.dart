// lib/widgets/update_stock.dart
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

const Color _borderColor = Color(0xFF3A71A4);
const Color _pillBg = Color(0xFF91C4D9);

/// Cara panggil:
/// showAddStockDialog(
///   context,
///   products: ['Milk', 'Taro', 'Croissant'],
///   onSubmit: (product, stock) { ... }
/// );
Future<void> showAddStockDialog(
  BuildContext context, {
  required List<String> products,
  required Future<void> Function(String selectedProduct, int stock) onSubmit,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AddStockDialog(
      products: products,
      onSubmit: onSubmit,
    ),
  );
}

class _AddStockDialog extends StatefulWidget {
  final List<String> products;
  final Future<void> Function(String selectedProduct, int stock) onSubmit;

  const _AddStockDialog({
    super.key,
    required this.products,
    required this.onSubmit,
  });

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  String? selectedProduct;
  final TextEditingController stockController = TextEditingController();
  final TextEditingController productSearchController = TextEditingController();

  final Map<String, int> categories = {
    'Minuman': 1,
    'Kue': 2,
    'Snack': 3,
  };
  String? selectedCategory;

  @override
  void dispose() {
    stockController.dispose();
    productSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _borderColor, width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                const Center(
                  child: Text(
                    'Tambah Stok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _labelText('Pilih Produk:'),
            const SizedBox(height: 6),
            _buildProductAutocomplete(),
            const SizedBox(height: 12),
            _labelText('Kategori:'),
            const SizedBox(height: 6),
            _buildCategoryDropdown(),
            const SizedBox(height: 12),
            _labelText('Jumlah Stok:'),
            const SizedBox(height: 6),
            _buildStockField(),
            const SizedBox(height: 18),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildProductAutocomplete() {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue text) {
          if (text.text.isEmpty) return const Iterable<String>.empty();
          return widget.products
              .where((p) => p.toLowerCase().contains(text.text.toLowerCase()));
        },
        onSelected: (selection) {
          setState(() => selectedProduct = selection);
        },
        fieldViewBuilder: (context, controller, node, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: node,
            onChanged: (v) => selectedProduct = null,
            onEditingComplete: onEditingComplete,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              hintText: 'Ketik atau pilih produk...',
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: const Text('Pilih Kategori...'),
          value: selectedCategory,
          items: categories.keys
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => selectedCategory = v),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 150,
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockField() {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: stockController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          hintText: 'Masukkan Jumlah Stok...',
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _onAddStockPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pillBg,
          foregroundColor: _borderColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: _borderColor, width: 2),
          ),
        ),
        child: const Text(
          'Tambah Stok',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _onAddStockPressed() async {
    if (selectedProduct == null) {
      await _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Pilih produk dari daftar",
      );
      return;
    }

    final int stock = int.tryParse(stockController.text.trim()) ?? 0;
    if (stock <= 0) {
      await _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Stok harus lebih dari 0",
      );
      return;
    }

    try {
      await widget.onSubmit(selectedProduct!, stock);

      if (!mounted) return;

      // Tutup dialog utama sebelum menampilkan popup sukses
      Navigator.of(context).pop();

      await _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Stok Berhasil \nDitambah",
      );
    } catch (e) {
      if (!mounted) return;
      await _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Terjadi kesalahan: $e",
      );
    }
  }

  Future<void> _showPopup({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _borderColor, width: 2),
        ),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 4),
                Icon(icon, size: 100, color: iconColor),
                const SizedBox(height: 24),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
      ),
    );
  }
}

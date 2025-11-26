// lib/widgets/edit_product.dart
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _borderColor = Color(0xFF3A71A4);
const Color _pillBg = Color(0xFF91C4D9);

/// Cara panggil:
/// showEditProductDialog(
///   context,
///   product: {
///     "namaproduk": "Milk",
///     "SKU": "MLK001",
///     "kategori": 1,
///     "harga": 12000,
///     "minimum": 5
///   },
///   categories: {'Minuman': 1, 'Kue': 2, 'Snack': 3},
///   onSubmit: (data) async { ... }
/// );
Future<void> showEditProductDialog(
  BuildContext context, {
  required Map<String, dynamic> product,
  required Map<String, int> categories,
  required Future<void> Function(Map<String, dynamic> data) onSubmit,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _EditProductDialog(
      product: product,
      categories: categories,
      onSubmit: onSubmit,
    ),
  );
}

class _EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, int> categories;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _EditProductDialog({
    super.key,
    required this.product,
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late TextEditingController nameController;
  late TextEditingController skuController;
  late TextEditingController priceController;
  late TextEditingController minStockController;

  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.product['namaproduk'] ?? '');
    skuController = TextEditingController(text: widget.product['SKU'] ?? '');
    priceController =
        TextEditingController(text: widget.product['harga']?.toString() ?? '');
    minStockController =
        TextEditingController(text: widget.product['minimum']?.toString() ?? '');
    selectedCategory = widget.categories.entries
        .firstWhere(
            (e) => e.value == widget.product['kategori'],
            orElse: () => widget.categories.entries.first)
        .key;
  }

  @override
  void dispose() {
    nameController.dispose();
    skuController.dispose();
    priceController.dispose();
    minStockController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  const Center(
                    child: Text(
                      'Edit Produk',
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
              _labelText('Nama Produk:'),
              const SizedBox(height: 6),
              _buildTextField(nameController, 'Masukkan nama produk...'),
              const SizedBox(height: 12),
              _labelText('SKU:'),
              const SizedBox(height: 6),
              _buildTextField(skuController, 'Masukkan SKU...'),
              const SizedBox(height: 12),
              _labelText('Kategori:'),
              const SizedBox(height: 6),
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              _labelText('Harga:'),
              const SizedBox(height: 6),
              _buildTextField(priceController, 'Masukkan harga',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _labelText('Batas Stok Minimum:'),
              const SizedBox(height: 6),
              _buildTextField(minStockController, 'Masukkan batas minimum',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 18),
              _buildSubmitButton(),
            ],
          ),
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

  Widget _buildTextField(TextEditingController controller, String hintText,
      {TextInputType? keyboardType}) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          hintText: hintText,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          value: selectedCategory,
          items: widget.categories.keys
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))
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

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _onEditProductPressed,
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
          'Simpan Perubahan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _onEditProductPressed() async {
    if (nameController.text.trim().isEmpty ||
        skuController.text.trim().isEmpty ||
        selectedCategory == null ||
        priceController.text.trim().isEmpty ||
        minStockController.text.trim().isEmpty) {
      await _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Lengkapi semua field",
      );
      return;
    }

    Map<String, dynamic> data = {
      "namaproduk": nameController.text.trim(),
      "SKU": skuController.text.trim(),
      "kategori": widget.categories[selectedCategory],
      "harga": double.tryParse(priceController.text.trim()) ?? 0,
      "minimum": int.tryParse(minStockController.text.trim()) ?? 0,
    };

    try {
      await widget.onSubmit(data);

      if (!mounted) return;
      Navigator.of(context).pop();

      await _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Produk Berhasil \nDiperbarui",
      );
    } catch (e) {
      if (!mounted) return;
      await _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Terjadi kesalahan: $e",
      );
      debugPrint(e.toString());
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

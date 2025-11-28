// lib/widgets/edit_product.dart
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

const Color _borderColor = Color(0xFF3A71A4);
const Color _pillBg = Color(0xFF91C4D9);

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
      rootContext: context, // ⬅ penting
      product: product,
      categories: categories,
      onSubmit: onSubmit,
    ),
  );
}

class _EditProductDialog extends StatefulWidget {
  final BuildContext rootContext; // ⬅ simpan context utama
  final Map<String, dynamic> product;
  final Map<String, int> categories;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _EditProductDialog({
    required this.rootContext,
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

  bool nameEmpty = false;
  bool skuEmpty = false;
  bool priceEmpty = false;
  bool priceNotNumber = false;
  bool minStockEmpty = false;
  bool minStockNotNumber = false;
  bool categoryError = false;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.product['namaproduk'] ?? '');
    skuController =
        TextEditingController(text: widget.product['SKU'] ?? '');
    priceController = TextEditingController(
        text: widget.product['harga']?.toString() ?? '');
    minStockController = TextEditingController(
        text: widget.product['minimum']?.toString() ?? '');

    selectedCategory = widget.categories.entries
        .firstWhere(
          (e) => e.value == widget.product['kategori'],
          orElse: () => widget.categories.entries.first,
        )
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

              _label("Nama Produk:"),
              _field(nameController, "Masukkan nama produk...", nameEmpty),
              if (nameEmpty) _error("Nama produk harus diisi"),
              const SizedBox(height: 12),

              _label("SKU:"),
              _field(skuController, "Masukkan SKU...", skuEmpty),
              if (skuEmpty) _error("SKU harus diisi"),
              const SizedBox(height: 12),

              _label("Kategori:"),
              _buildCategoryDropdown(),
              if (categoryError) _error("Kategori harus dipilih"),
              const SizedBox(height: 12),

              _label("Harga:"),
              _field(
                priceController,
                "Masukkan harga",
                priceEmpty || priceNotNumber,
                keyboardType: TextInputType.number,
              ),
              if (priceEmpty)
                _error("Harga harus diisi")
              else if (priceNotNumber)
                _error("Harga harus berupa angka"),
              const SizedBox(height: 12),

              _label("Batas Stok Minimum:"),
              _field(
                minStockController,
                "Masukkan batas minimum",
                minStockEmpty || minStockNotNumber,
                keyboardType: TextInputType.number,
              ),
              if (minStockEmpty)
                _error("Minimum stok harus diisi")
              else if (minStockNotNumber)
                _error("Minimum stok harus berupa angka"),
              const SizedBox(height: 20),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );

  Widget _error(String txt) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          txt,
          style: const TextStyle(color: Colors.red, fontSize: 11),
        ),
      );

  Widget _field(
    TextEditingController c,
    String hint,
    bool error, {
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: error ? Colors.red : _borderColor,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: TextField(
          controller: c,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: categoryError ? Colors.red : _borderColor,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          value: selectedCategory,
          items: widget.categories.keys
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => selectedCategory = value);
          },
          buttonStyleData: const ButtonStyleData(height: 32),
          dropdownStyleData: const DropdownStyleData(maxHeight: 200),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pillBg,
          foregroundColor: _borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: _borderColor, width: 2),
          ),
        ),
        child: const Text(
          "Simpan Perubahan",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    setState(() {
      nameEmpty = nameController.text.trim().isEmpty;
      skuEmpty = skuController.text.trim().isEmpty;

      priceEmpty = priceController.text.trim().isEmpty;
      priceNotNumber =
          !priceEmpty && double.tryParse(priceController.text.trim()) == null;

      minStockEmpty = minStockController.text.trim().isEmpty;
      minStockNotNumber =
          !minStockEmpty && int.tryParse(minStockController.text.trim()) == null;

      categoryError = selectedCategory == null;
    });

    if (nameEmpty ||
        skuEmpty ||
        priceEmpty ||
        priceNotNumber ||
        minStockEmpty ||
        minStockNotNumber ||
        categoryError) {
      return;
    }

    Map<String, dynamic> data = {
      "namaproduk": nameController.text.trim(),
      "SKU": skuController.text.trim(),
      "kategori": widget.categories[selectedCategory],
      "harga": double.parse(priceController.text.trim()),
      "minimum": int.parse(minStockController.text.trim()),
    };

    try {
      await widget.onSubmit(data);

      if (!mounted) return;

      // Tutup dialog edit
      Navigator.of(context).pop();

      // Popup menggunakan rootContext
      await _popup(
        widget.rootContext,
        Icons.check_circle,
        Colors.green,
        "Produk Berhasil \nDiperbarui",
      );
    } catch (e) {
      await _popup(
        widget.rootContext,
        Icons.warning_rounded,
        Colors.red,
        "Terjadi kesalahan: $e",
      );
    }
  }

  Future<void> _popup(
    BuildContext ctx,
    IconData icon,
    Color color,
    String text,
  ) {
    return showDialog(
      barrierDismissible: false,
      context: ctx, // ⬅ aman
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx), // ⬅ aman
                  icon: const Icon(Icons.close),
                ),
              ),
              Icon(icon, size: 100, color: color),
              const SizedBox(height: 18),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

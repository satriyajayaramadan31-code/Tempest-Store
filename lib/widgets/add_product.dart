// lib/widgets/add_product.dart
import 'dart:typed_data';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _borderColor = Color(0xFF3A71A4);
const Color _pillBg = Color(0xFF91C4D9);

/// Cara panggil:
/// showAddProductDialog(
///   context,
///   categories: {'Minuman': 1, 'Kue': 2, 'Snack': 3},
///   onSubmit: (data) async { ... }
/// );
Future<void> showAddProductDialog(
  BuildContext context, {
  required Map<String, int> categories,
  required Future<void> Function(Map<String, dynamic> data) onSubmit,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AddProductDialog(
      categories: categories,
      onSubmit: onSubmit,
    ),
  );
}

class _AddProductDialog extends StatefulWidget {
  final Map<String, int> categories;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _AddProductDialog({
    super.key,
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();

  String? selectedCategory;
  Uint8List? selectedImageBytes;
  String? selectedImageName;

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
                      'Tambah Produk',
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
              const SizedBox(height: 12),
              _labelText('Foto Produk:'),
              const SizedBox(height: 6),
              _buildImagePicker(),
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
          hint: const Text(
            'Pilih Kategori...',
            style: TextStyle(fontSize: 12),
          ),
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

  Widget _buildImagePicker() {
    return ElevatedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.photo_library, size: 18),
      label: Text(
        selectedImageBytes != null ? "Ganti Foto" : "Pilih Foto",
        style: const TextStyle(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _pillBg,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _borderColor, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          selectedImageBytes = result.files.single.bytes;
          selectedImageName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Gagal memilih gambar: $e");
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _onAddProductPressed,
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
          'Tambah Produk',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _onAddProductPressed() async {
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
      if (selectedImageBytes != null && selectedImageName != null) {
        final fileExt = selectedImageName!.split('.').last;
        final fileName = '${data["SKU"]}.$fileExt';

        await Supabase.instance.client
            .storage
            .from('produk_image')
            .uploadBinary(fileName, selectedImageBytes!,
                fileOptions: FileOptions(upsert: true));

        final publicUrl = Supabase.instance.client
            .storage
            .from('produk_image')
            .getPublicUrl(fileName);

        data['foto_url'] = publicUrl;
      }

      await widget.onSubmit(data);

      if (!mounted) return;
      Navigator.of(context).pop();

      await _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Produk Berhasil \nDitambahkan",
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

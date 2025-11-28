// lib/widgets/add_product.dart
import 'dart:typed_data';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _borderColor = Color(0xFF3A71A4);
const Color _pillBg = Color(0xFF91C4D9);

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

  bool nameError = false;
  bool skuError = false;
  bool categoryError = false;

  bool priceEmptyError = false;
  bool priceFormatError = false;

  bool minStockEmptyError = false;
  bool minStockFormatError = false;

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
              _buildTextField(
                nameController,
                'Masukkan nama produk...',
                error: nameError,
              ),
              if (nameError) _errorText("Kolom nama produk harus diisi"),
              const SizedBox(height: 12),

              _labelText('SKU:'),
              const SizedBox(height: 6),
              _buildTextField(
                skuController,
                'Masukkan SKU...',
                error: skuError,
              ),
              if (skuError) _errorText("Kolom SKU harus diisi"),
              const SizedBox(height: 12),

              _labelText('Kategori:'),
              const SizedBox(height: 6),
              _buildCategoryDropdown(),
              if (categoryError) _errorText("Kategori harus dipilih"),
              const SizedBox(height: 12),

              _labelText('Harga:'),
              const SizedBox(height: 6),
              _buildTextField(
                priceController,
                'Masukkan harga',
                keyboardType: TextInputType.number,
                error: priceEmptyError || priceFormatError,
              ),
              if (priceEmptyError) _errorText("Kolom harga harus diisi")
              else if (priceFormatError) _errorText("Harga harus berupa angka"),
              const SizedBox(height: 12),

              _labelText('Batas Stok Minimum:'),
              const SizedBox(height: 6),
              _buildTextField(
                minStockController,
                'Masukkan batas minimum',
                keyboardType: TextInputType.number,
                error: minStockEmptyError || minStockFormatError,
              ),
              if (minStockEmptyError)
                _errorText("Kolom stok minimum harus diisi")
              else if (minStockFormatError)
                _errorText("Stok minimum harus berupa angka"),
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

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    TextInputType? keyboardType,
    required bool error,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: error ? Colors.red : _borderColor,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
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
        border: Border.all(
          color: categoryError ? Colors.red : _borderColor,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.zero,
            height: 20,
          ),
          menuItemStyleData: const MenuItemStyleData(height: 28),
          hint: const Text('Pilih Kategori...', style: TextStyle(fontSize: 11)),
          value: selectedCategory,
          items: widget.categories.keys
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => selectedCategory = v),
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
    setState(() {
      nameError = nameController.text.trim().isEmpty;
      skuError = skuController.text.trim().isEmpty;
      categoryError = selectedCategory == null;

      priceEmptyError = priceController.text.trim().isEmpty;
      priceFormatError =
          !priceEmptyError && double.tryParse(priceController.text.trim()) == null;

      minStockEmptyError = minStockController.text.trim().isEmpty;
      minStockFormatError = !minStockEmptyError &&
          int.tryParse(minStockController.text.trim()) == null;
    });

    if (nameError ||
        skuError ||
        categoryError ||
        priceEmptyError ||
        priceFormatError ||
        minStockEmptyError ||
        minStockFormatError) {
      return;
    }

    final harga = double.parse(priceController.text);
    final minimum = int.parse(minStockController.text);

    Map<String, dynamic> data = {
      "namaproduk": nameController.text.trim(),
      "SKU": skuController.text.trim(),
      "kategori": widget.categories[selectedCategory],
      "harga": harga,
      "minimum": minimum,
    };

    try {
      if (selectedImageBytes != null && selectedImageName != null) {
        final ext = selectedImageName!.split('.').last;
        final fileName = '${data["SKU"]}.$ext';

        await Supabase.instance.client.storage
            .from('produk_image')
            .uploadBinary(
              fileName,
              selectedImageBytes!,
              fileOptions: FileOptions(upsert: true),
            );

        final publicUrl = Supabase.instance.client.storage
            .from('produk_image')
            .getPublicUrl(fileName);

        data['foto_url'] = publicUrl;
      }

      await widget.onSubmit(data);

      if (!mounted) return;
      Navigator.of(context).pop();

      await _showSuccess("Produk Berhasil \nDitambahkan");
    } catch (e) {
      if (!mounted) return;
      await _showError("Terjadi kesalahan: $e");
    }
  }

  Future<void> _showError(String text) {
    return _showPopup(
      icon: Icons.warning_rounded,
      iconColor: Colors.red,
      text: text,
    );
  }

  Future<void> _showSuccess(String text) {
    return _showPopup(
      icon: Icons.check_circle,
      iconColor: Colors.green,
      text: text,
    );
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

// lib/widgets/update_stock.dart
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

const Color _borderColor = Color(0xFF3A71A4);
const Color _pillBg = Color(0xFF91C4D9);

Future<void> showAddStockDialog(
  BuildContext context, {
  required List<String> products,
  required Future<void> Function(String selectedProduct, int stock) onSubmit,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AddStockDialog(
      rootContext: context,  // <- penting!
      products: products,
      onSubmit: onSubmit,
    ),
  );
}

class _AddStockDialog extends StatefulWidget {
  final BuildContext rootContext; // <- simpan context utama
  final List<String> products;
  final Future<void> Function(String selectedProduct, int stock) onSubmit;

  const _AddStockDialog({
    super.key,
    required this.rootContext,
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

  bool errorProduct = false;
  bool errorCategory = false;
  bool errorStock = false;
  bool stockNotNumber = false;

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
        padding: const EdgeInsets.all(18),
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
            _buildProductAutocomplete(),
            if (errorProduct) _errorText("Produk harus dipilih dari daftar"),
            const SizedBox(height: 12),

            _labelText('Kategori:'),
            _buildCategoryDropdown(),
            if (errorCategory) _errorText("Kategori harus dipilih"),
            const SizedBox(height: 12),

            _labelText('Jumlah Stok:'),
            _buildStockField(),
            if (errorStock) _errorText("Stok wajib diisi"),
            if (stockNotNumber) _errorText("Stok harus berupa angka"),
            const SizedBox(height: 20),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

  Widget _buildProductAutocomplete() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: errorProduct ? Colors.red : _borderColor,
          width: 1.5,
        ),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue text) {
          if (text.text.isEmpty) return const Iterable<String>.empty();
          return widget.products.where(
            (p) => p.toLowerCase().contains(text.text.trim().toLowerCase()),
          );
        },
        onSelected: (selection) {
          setState(() {
            selectedProduct = selection;
            errorProduct = false;
          });
        },
        fieldViewBuilder: (context, controller, node, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: node,
            onChanged: (v) {
              selectedProduct = null;
              setState(() => errorProduct = false);
            },
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              hintText: "Ketik atau pilih produk...",
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: errorCategory ? Colors.red : _borderColor,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: const Text("Pilih Kategori...", style: TextStyle(fontSize: 12)),
          value: selectedCategory,
          items: categories.keys
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              selectedCategory = v;
              errorCategory = false;
            });
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.zero,
            height: 20,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _borderColor, width: 1.5),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 28),
        ),
      ),
    );
  }

  Widget _buildStockField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (errorStock || stockNotNumber) ? Colors.red : _borderColor,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: stockController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 6),
          hintText: "Masukkan jumlah stok...",
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _onAddStockPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pillBg,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: _borderColor, width: 2),
          ),
        ),
        child: const Text(
          "Tambah Stok",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }

  // ===============================
  // VALIDASI + SUBMIT
  // ===============================
  Future<void> _onAddStockPressed() async {
    setState(() {
      errorProduct = selectedProduct == null;
      errorCategory = selectedCategory == null;

      errorStock = stockController.text.trim().isEmpty;
      stockNotNumber =
          !errorStock && int.tryParse(stockController.text.trim()) == null;
    });

    if (errorProduct || errorCategory || errorStock || stockNotNumber) return;

    final stock = int.parse(stockController.text.trim());

    try {
      await widget.onSubmit(selectedProduct!, stock);
      if (!mounted) return;

      Navigator.of(context).pop(); // tutup dialog utama

      // tampilkan popup SUKSES dengan context ROOT
      await _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Stok Berhasil \nDitambah",
        ctx: widget.rootContext,
      );
    } catch (e) {
      await _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Terjadi kesalahan: $e",
        ctx: widget.rootContext,
      );
    }
  }

  // ===============================
  // POPUP — pakai root context!
  // ===============================
  Future<void> _showPopup({
    required IconData icon,
    required Color iconColor,
    required String text,
    required BuildContext ctx,  // <- pakai context aman
  }) {
    return showDialog(
      barrierDismissible: false,
      context: ctx,
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
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ),
              Icon(icon, size: 100, color: iconColor),
              const SizedBox(height: 18),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

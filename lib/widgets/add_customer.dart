// lib/widgets/add_customer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tempest_store/services/supabase_service.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final formKey = GlobalKey<FormState>();

  final nameCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final emailCtl = TextEditingController();

  bool loading = false;

  final Color borderColor = const Color(0xFF3A71A4);
  final Color saveColor = const Color(0xFF91C4D9);

  @override
  void dispose() {
    nameCtl.dispose();
    addressCtl.dispose();
    phoneCtl.dispose();
    emailCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final service = SupabaseService();
      await service.addPelanggan(
        name: nameCtl.text.trim(),
        alamat: addressCtl.text.trim(),
        nomortelepon: phoneCtl.text.trim(),
        email: emailCtl.text.trim(),
      );

      if (mounted) Navigator.of(context).pop();

      _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Pelanggan Berhasil\nDitambah",
      );
    } catch (e) {
      _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Terjadi kesalahan: $e",
      );
      print(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showPopup({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol close di Row atas
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
                // Icon besar
                Icon(icon, size: 100, color: iconColor),
                const SizedBox(height: 24),
                // Teks
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

  InputDecoration fieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -12,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 22),
                  splashRadius: 18,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        "Tambah Pelanggan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _fieldLabel("Nama Lengkap:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: nameCtl,
                        decoration: fieldDecoration(),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Wajib diisi" : null,
                      ),
                    ),

                    const SizedBox(height: 8),
                    _fieldLabel("Email:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: emailCtl,
                        decoration: fieldDecoration(),
                      ),
                    ),

                    const SizedBox(height: 8),
                    _fieldLabel("Alamat:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: addressCtl,
                        decoration: fieldDecoration(),
                      ),
                    ),

                    const SizedBox(height: 8),
                    _fieldLabel("Nomor Telepon:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: phoneCtl,
                        decoration: fieldDecoration(),
                      ),
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saveColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor, width: 1.5),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Simpan",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: BorderSide(color: borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

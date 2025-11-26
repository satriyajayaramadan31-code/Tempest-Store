// lib/widgets/edit_customer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tempest_store/services/supabase_service.dart';

class EditCustomerDialog extends StatefulWidget {
  final Map<String, dynamic> customer; // data pelanggan yang mau diedit

  const EditCustomerDialog({super.key, required this.customer});

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController nameCtl;
  late TextEditingController emailCtl;
  late TextEditingController addressCtl;
  late TextEditingController phoneCtl;
  bool loading = false;

  final Color borderColor = const Color(0xFF3A71A4);
  final Color saveColor = const Color(0xFF91C4D9);

  @override
  void initState() {
    super.initState();
    nameCtl = TextEditingController(text: widget.customer['namapelanggan'] ?? '');
    emailCtl = TextEditingController(text: widget.customer['email'] ?? '');
    addressCtl = TextEditingController(text: widget.customer['alamat'] ?? '');
    phoneCtl = TextEditingController(text: widget.customer['nomortelepon'] ?? '');
  }

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    addressCtl.dispose();
    phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final service = SupabaseService();

      await service.updatePelanggan(
        widget.customer['pelangganid'],
        {
          'namapelanggan': nameCtl.text.trim(),
          'email': emailCtl.text.trim(),
          'alamat': addressCtl.text.trim(),
          'nomortelepon': phoneCtl.text.trim(),
        },
      );

      if (mounted) Navigator.of(context).pop();

      _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Pelanggan Berhasil\nDiedit",
      );
    } on TimeoutException {
      _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Koneksi lambat, coba lagi.",
      );
    } catch (e) {
      _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Terjadi kesalahan: $e",
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah Anda yakin ingin menghapus pelanggan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);
    try {
      final service = SupabaseService();
      await service.deletePelanggan(widget.customer['pelangganid']);

      if (mounted) Navigator.of(context).pop();

      _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Pelanggan Berhasil Dihapus",
      );
    } catch (e) {
      _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Gagal menghapus: $e",
      );
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
                  style: const TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold),
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
      isDense: true,
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
                        "Edit Pelanggan",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Nama
                    _fieldLabel("Nama Lengkap:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: nameCtl,
                        decoration: fieldDecoration(),
                        validator: (v) => v == null || v.trim().isEmpty ? "Wajib diisi" : null,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Email
                    _fieldLabel("Email:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: emailCtl,
                        decoration: fieldDecoration(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Wajib diisi";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "Format email salah";
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Alamat
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

                    // Nomor Telepon
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

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saveColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Simpan",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tombol Hapus
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: OutlinedButton(
                        onPressed: loading ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

// lib/widgets/edit_customer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tempest_store/services/supabase_service.dart';

class EditCustomerDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

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

  // error messages (null = no error)
  String? nameErrorMsg;
  String? emailErrorMsg;
  String? addressErrorMsg;
  String? phoneErrorMsg;

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

  InputDecoration fieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      // don't rely on built-in errorText to avoid field resize — show errors manually
      errorStyle: const TextStyle(fontSize: 0, height: 0),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _errorText(String? txt) {
    if (txt == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          txt,
          textAlign: TextAlign.left,
          style: const TextStyle(color: Colors.red, fontSize: 11),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // reset errors
    setState(() {
      nameErrorMsg = null;
      emailErrorMsg = null;
      addressErrorMsg = null;
      phoneErrorMsg = null;
    });

    final name = nameCtl.text.trim();
    final email = emailCtl.text.trim();
    final address = addressCtl.text.trim();
    final phone = phoneCtl.text.trim();

    bool hasError = false;

    if (name.isEmpty) {
      nameErrorMsg = "Wajib diisi";
      hasError = true;
    }

    if (email.isEmpty) {
      emailErrorMsg = "Wajib diisi";
      hasError = true;
    } else if (!email.endsWith("@gmail.com")) {
      emailErrorMsg = "Harus berakhiran @gmail.com";
      hasError = true;
    }

    if (address.isEmpty) {
      addressErrorMsg = "Wajib diisi";
      hasError = true;
    }

    if (phone.isEmpty) {
      phoneErrorMsg = "Wajib diisi";
      hasError = true;
    } else if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      phoneErrorMsg = "Hanya boleh angka";
      hasError = true;
    }

    if (hasError) {
      // show errors under fields without changing field heights
      setState(() {});
      return;
    }

    setState(() => loading = true);

    try {
      final service = SupabaseService();

      await service.updatePelanggan(
        widget.customer['pelangganid'],
        {
          'namapelanggan': name,
          'email': email,
          'alamat': address,
          'nomortelepon': phone,
        },
      );

      if (mounted) Navigator.of(context).pop();

      _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Pelanggan Berhasil\nDiedit",
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

                    // NAMA
                    _fieldLabel("Nama Lengkap:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: nameCtl,
                        decoration: fieldDecoration(),
                        // no validator here — we show error text manually below
                      ),
                    ),
                    _errorText(nameErrorMsg),
                    const SizedBox(height: 8),

                    // EMAIL
                    _fieldLabel("Email:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: emailCtl,
                        decoration: fieldDecoration(),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    _errorText(emailErrorMsg),
                    const SizedBox(height: 8),

                    // ALAMAT
                    _fieldLabel("Alamat:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: addressCtl,
                        decoration: fieldDecoration(),
                      ),
                    ),
                    _errorText(addressErrorMsg),
                    const SizedBox(height: 8),

                    // NOMOR TELEPON
                    _fieldLabel("Nomor Telepon:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextFormField(
                        controller: phoneCtl,
                        decoration: fieldDecoration(),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    _errorText(phoneErrorMsg),
                    const SizedBox(height: 18),

                    // BUTTON SIMPAN
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
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BUTTON HAPUS
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: OutlinedButton(
                        onPressed: loading ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

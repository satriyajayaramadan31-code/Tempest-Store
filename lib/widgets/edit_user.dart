import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController nameCtl;
  late TextEditingController emailCtl;
  String? roleVal;

  bool loading = false;

  final Color borderColor = const Color(0xFF3A71A4);
  final Color saveColor = const Color(0xFF91C4D9);

  @override
  void initState() {
    super.initState();
    nameCtl = TextEditingController(text: widget.user['username'] ?? '');
    emailCtl = TextEditingController(text: widget.user['email'] ?? '');
    roleVal = widget.user['role'];
  }

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final payload = {
      'auth_uid': widget.user['auth_uid'],
      'id': widget.user['id'],
      'email': emailCtl.text.trim(),
      'username': nameCtl.text.trim(),
      'role': roleVal,
    };

    debugPrint('[EditUser] Payload: $payload');

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'update-user',
        body: payload,
      );

      Map<String, dynamic> result = {};
      if (response.data != null) {
        if (response.data is String) {
          result = jsonDecode(response.data);
        } else if (response.data is Map) {
          result = Map<String, dynamic>.from(response.data);
        }
      }

      debugPrint('[EditUser] Response: $result');

      if (result.containsKey("error")) {
        _showPopup(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          text: result["error"],
        );
        return;
      }

      if (mounted) Navigator.pop(context, true);

      _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Pengguna Berhasil\nDiperbarui",
      );
    } on TimeoutException {
      _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Koneksi lambat, coba lagi.",
      );
    } catch (e, st) {
      debugPrint('[EditUser] Exception: $e\n$st');
      _showPopup(
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        text: "Terjadi kesalahan: $e",
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ----------------------------------------------------
  // ✨ Popup sama seperti Tambah User
  // ----------------------------------------------------
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

  InputDecoration field() {
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
                        "Edit Pengguna",
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
                        decoration: field(),
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
                        decoration: field(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Email wajib";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return "Format email salah";
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                    _fieldLabel("Role:"),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: DropdownButtonFormField<String>(
                        decoration: field(),
                        dropdownColor: Colors.white,
                        value: roleVal,
                        items: const [
                          DropdownMenuItem(value: "admin", child: Text("Admin")),
                          DropdownMenuItem(value: "kasir", child: Text("Kasir")),
                        ],
                        onChanged: (v) => setState(() => roleVal = v),
                        validator: (v) => v == null ? "Pilih role" : null,
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

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

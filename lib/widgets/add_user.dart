import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tempest_store/services/supabase_service.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final nameCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();

  String? roleVal;
  bool loading = false;

  bool nameEmpty = false;
  bool emailEmpty = false;
  bool emailWrong = false;
  bool passEmpty = false;
  bool passShort = false;
  bool roleError = false;

  final Color borderColor = const Color(0xFF3A71A4);
  final Color saveColor = const Color(0xFF91C4D9);

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      nameEmpty = nameCtl.text.trim().isEmpty;
      emailEmpty = emailCtl.text.trim().isEmpty;
      emailWrong = !emailEmpty &&
          !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(emailCtl.text.trim());
      passEmpty = passCtl.text.trim().isEmpty;
      passShort = !passEmpty && passCtl.text.trim().length < 6;
      roleError = roleVal == null;
    });

    if (nameEmpty ||
        emailEmpty ||
        emailWrong ||
        passEmpty ||
        passShort ||
        roleError) {
      return;
    }

    setState(() => loading = true);

    final payload = {
      'email': emailCtl.text.trim(),
      'password': passCtl.text.trim(),
      'username': nameCtl.text.trim(),
      'role': roleVal ?? 'kasir',
    };

    try {
      final response = await SupabaseService.client.functions.invoke(
        'create-user',
        body: payload,
      );

      Map<String, dynamic> data = {};
      if (response.data != null) {
        if (response.data is String && (response.data as String).isNotEmpty) {
          data = jsonDecode(response.data as String);
        } else if (response.data is Map<String, dynamic>) {
          data = response.data;
        }
      }

      if (data.containsKey("error")) {
        _showPopup(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          text: data["error"].toString(),
        );
      } else {
        if (mounted) Navigator.of(context).pop();

        _showPopup(
          icon: Icons.check_circle,
          iconColor: Colors.green,
          text: "Pengguna Berhasil\nDitambah",
        );
      }
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

  Widget _fieldWrapper({
    required TextEditingController c,
    required bool error,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: error ? Colors.red : borderColor,
          width: 1.3,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          onChanged: (_) {
            setState(() {
              if (c == nameCtl) nameEmpty = false;
              if (c == emailCtl) {
                emailEmpty = false;
                emailWrong = false;
              }
              if (c == passCtl) {
                passEmpty = false;
                passShort = false;
              }
            });
          },
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

  Widget _errorText(String t) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t,
            textAlign: TextAlign.left,
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 340,
          maxWidth: 400,
        ),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Tambah Pengguna",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel("Nama Lengkap:"),
                  _fieldWrapper(
                    c: nameCtl,
                    error: nameEmpty,
                    hint: "Masukkan nama...",
                  ),
                  if (nameEmpty) _errorText("Nama wajib diisi"),

                  const SizedBox(height: 10),
                  _fieldLabel("Email:"),
                  _fieldWrapper(
                    c: emailCtl,
                    error: emailEmpty || emailWrong,
                    hint: "Masukkan email...",
                  ),
                  if (emailEmpty)
                    _errorText("Email wajib diisi")
                  else if (emailWrong)
                    _errorText("Format email salah"),

                  const SizedBox(height: 10),
                  _fieldLabel("Password:"),
                  _fieldWrapper(
                    c: passCtl,
                    error: passEmpty || passShort,
                    obscure: true,
                    hint: "Minimal 6 karakter",
                  ),
                  if (passEmpty)
                    _errorText("Password wajib diisi")
                  else if (passShort)
                    _errorText("Minimal 6 karakter"),

                  const SizedBox(height: 10),
                  _fieldLabel("Role:"),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: roleError ? Colors.red : borderColor,
                          width: 1.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: roleVal,
                        items: const [
                          DropdownMenuItem(
                              value: "admin", child: Text("Admin")),
                          DropdownMenuItem(
                              value: "kasir", child: Text("Kasir")),
                        ],
                        onChanged: (v) {
                          setState(() {
                            roleVal = v;
                            roleError = false;
                          });
                        },
                      ),
                    ),
                  ),
                  if (roleError) _errorText("Pilih role"),

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
                                color: Colors.white,
                              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

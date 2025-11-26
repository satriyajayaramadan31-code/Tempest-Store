import 'package:flutter/material.dart';
import 'package:tempest_store/widgets/app_shell.dart';
import 'package:tempest_store/services/supabase_service.dart';
import 'package:tempest_store/widgets/update_stok.dart';
import 'package:tempest_store/widgets/add_product.dart';
import 'package:tempest_store/widgets/edit_product.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _borderColor = Color(0xFF3A71A4);

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  static const Color topBg = Color(0xFF93B9E8);
  static const Color borderColor = Color(0xFF3A71A4);
  static const Color cardBg = Colors.white;
  static const double horizontalPadding = 12.0;

  final SupabaseService _svc = SupabaseService();
  List<Map<String, dynamic>> products = [];
  String query = '';
  bool loading = false;
  String? error;
  String? userRole;

  RealtimeChannel? _channel;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final Map<String, int> categories = {
    'Minuman': 1,
    'Kue': 2,
    'Snack': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _subscribeRealtime();
    _loadUserRole();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await _svc.getUserRole();
    if (!mounted) return;
    setState(() {
      userRole = role;
    });
  }

  String _safeString(Map<String, dynamic> map, String key,
      [String defaultValue = '']) {
    final val = map[key] ?? map[key.toUpperCase()];
    if (val == null) return defaultValue;
    return val.toString();
  }

  Map<String, dynamic> _normalizeProduct(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);

    final hargaRaw = map['harga'];
    num hargaNum =
        hargaRaw is num ? hargaRaw : num.tryParse(hargaRaw?.toString() ?? '0') ?? 0;
    map['harga_num'] = hargaNum;

    final stokRaw = map['stok'];
    int stokInt =
        (stokRaw is num) ? stokRaw.toInt() : int.tryParse(stokRaw?.toString() ?? '0') ?? 0;
    map['stok_int'] = stokInt;

    final kategoriRaw = map['kategori'];
    int kategoriId = (kategoriRaw is num)
        ? kategoriRaw.toInt()
        : int.tryParse(kategoriRaw?.toString() ?? '0') ?? 0;
    map['kategori_id'] = kategoriId;

    String kategoriStr = '-';
    switch (kategoriId) {
      case 1:
        kategoriStr = 'Minuman';
        break;
      case 2:
        kategoriStr = 'Kue';
        break;
      case 3:
        kategoriStr = 'Snack';
        break;
    }
    map['kategori_str'] = kategoriStr;

    map['name'] = _safeString(map, 'namaproduk', 'Unknown');
    map['SKU'] = _safeString(map, 'SKU', '-');

    return map;
  }

  Future<void> _loadProducts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await _svc.getProduk();
      products = data.map((raw) => _normalizeProduct(raw)).toList();
    } catch (e, st) {
      error = e.toString();
      debugPrint('Error loadProducts: $e\n$st');
    } finally {
      setState(() => loading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client.channel('public:kasir_produk')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'kasir_produk',
        callback: (payload) {
          final newRow = payload.newRecord;
          final oldRow = payload.oldRecord;

          if (payload.eventType == PostgresChangeEvent.insert &&
              newRow != null &&
              (newRow['is_deleted'] == null || newRow['is_deleted'] == false)) {
            setState(() {
              products.insert(0, _normalizeProduct(newRow));
            });
          }

          if (payload.eventType == PostgresChangeEvent.update && newRow != null) {
            final id = newRow['produkid'];
            final idx = products.indexWhere((p) => p['produkid'] == id);

            if (newRow['is_deleted'] == true) {
              if (idx != -1) {
                setState(() {
                  products.removeAt(idx);
                });
              }
              return;
            }

            if (idx != -1) {
              setState(() {
                products[idx] = _normalizeProduct(newRow);
              });
            } else {
              setState(() {
                products.insert(0, _normalizeProduct(newRow));
              });
            }
          }

          if (payload.eventType == PostgresChangeEvent.delete && oldRow != null) {
            final id = oldRow['produkid'];
            setState(() {
              products.removeWhere((p) => p['produkid'] == id);
            });
          }
        },
      )
      ..subscribe();
  }

  List<Map<String, dynamic>> get lowStock => products.where((p) {
        final stok = p['stok_int'] ?? 0;
        final minRaw = p['minimum'];
        final min =
            (minRaw is num) ? minRaw.toInt() : int.tryParse(minRaw?.toString() ?? '0') ?? 0;
        return stok < (min > 0 ? min : 10);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final filtered = products.where((p) {
      if (q.isEmpty) return true;
      final name = _safeString(p, 'name').toLowerCase();
      final sku = _safeString(p, 'SKU').toLowerCase();
      final kategori = _safeString(p, 'kategori_str').toLowerCase();
      return name.contains(q) || sku.contains(q) || kategori.contains(q);
    }).toList();

    return AppShell(
      title: 'Manajemen Produk',
      child: Container(
        color: topBg,
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildTitle(),
                const SizedBox(height: 10),
                _buildActionButtons(),
                const SizedBox(height: 12),
                if (lowStock.isNotEmpty) _buildLowStockCard(lowStock),
                const SizedBox(height: 10),
                _buildSearchBox(),
                const SizedBox(height: 12),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Error: $error',
                                  style: const TextStyle(color: Colors.red)),
                            )
                          : _buildProductList(filtered),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manajemen Produk',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
          const SizedBox(height: 4),
          Text('Total ada ${products.length} produk',
              style: const TextStyle(
                  fontSize: 13,
                  color: borderColor,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildActionButtons() {
    Widget button(String label, IconData icon, VoidCallback onPressed) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF91C4D9),
            foregroundColor: Colors.white,
            side: const BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          onPressed: onPressed,
        ),
      );
    }

    return Row(
      children: [
        button('Tambah Produk', Icons.add, () {
          showAddProductDialog(
            context,
            categories: categories,
            onSubmit: (data) async {
              try {
                await _svc.addProduk(data);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Gagal tambah produk: $e')));
              }
            },
          );
        }),
        if (userRole == 'admin') // hanya tampil untuk admin
          button('Tambah Stok', Icons.add, () {
            final productNames =
                products.map((p) => _safeString(p, 'name')).toList();

            showAddStockDialog(
              context,
              products: productNames,
              onSubmit: (productName, stock) async {
                final selected =
                    products.firstWhere((p) => p['name'] == productName);

                final id = selected['produkid'];

                await _svc.tambahStok(id, stock);
              },
            );
          }),
        const Spacer(),
      ],
    );
  }

  Widget _buildLowStockCard(List<Map<String, dynamic>> lowStock) {
    final item = lowStock.first;
    final nama = _safeString(item, 'name', 'Produk');
    final stok = item['stok_int'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 40, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${lowStock.length} Produk Memiliki Stok Rendah',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text('$nama — Stok: $stok',
                    style: const TextStyle(
                        color: borderColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                  hintText: 'Cari Produk, SKU, atau Kategori',
                  border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> data) {
    return ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(
                          bottom:
                              BorderSide(color: borderColor, width: 2.8))),
                  child: Row(
                    children: const [
                      SizedBox(
                          width: 200,
                          child: Text('Nama Produk',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 100,
                          child: Text('SKU',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 120,
                          child: Text('Kategori',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 100,
                          child: Text('Harga',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 60,
                          child: Text('Stok',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 100,
                          child: Text('Status',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 80,
                          child: Text('Aksi',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...data.map((p) {
                  final stok = p['stok_int'] ?? 0;
                  final minRaw = p['minimum'];
                  final min = (minRaw is num)
                      ? minRaw.toInt()
                      : int.tryParse(minRaw?.toString() ?? '0') ?? 0;
                  final isLow = stok < (min > 0 ? min : 10);

                  final hargaNum = p['harga_num'];
                  final harga = (hargaNum != null && hargaNum is num)
                      ? _currencyFormat.format(hargaNum)
                      : '-';

                  return Container(
                    decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: borderColor, width: 2))),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              _safeString(p, 'name'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: 100,
                            child: Text(_safeString(p, 'SKU', '-'),
                                textAlign: TextAlign.center)),
                        SizedBox(
                            width: 120,
                            child: Text(_safeString(p, 'kategori_str', '-'),
                                textAlign: TextAlign.center)),
                        SizedBox(
                            width: 100,
                            child: Text(harga, textAlign: TextAlign.center)),
                        SizedBox(
                            width: 60,
                            child: Text('$stok', textAlign: TextAlign.center)),
                        SizedBox(
                          width: 100,
                          child: Text(
                            isLow ? 'Stok Rendah' : 'Normal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.orange : Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _onEditProduct(p),
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 18),
                                  onPressed: () => _onDeleteProduct(p),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onEditProduct(Map<String, dynamic> p) {
    showEditProductDialog(
      context,
      product: p,
      categories: categories,
      onSubmit: (updatedData) async {
        try {
          final id = int.parse(p['produkid'].toString());
          await _svc.updateProduk(id, updatedData);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal update: $e')));
        }
      },
    );
  }

  void _onDeleteProduct(Map<String, dynamic> p) async {
    final sku = _safeString(p, 'SKU');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Hapus produk?'),
        content: Text('Yakin ingin menghapus "${_safeString(p, 'name', '-')}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                side: BorderSide(color: _borderColor, width: 2),
                backgroundColor: topBg,
              ),
              child: const Text('Batal', style: TextStyle(color: Colors.white))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                side: BorderSide(color: _borderColor, width: 2),
                backgroundColor: topBg,
              ),
              child: const Text('Ya', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _svc.deleteProdukBySKU(sku);

      if (!mounted) return;
      setState(() {
        products.removeWhere((x) => _safeString(x, 'SKU') == sku);
      });

      if (!mounted) return;
      await _showPopup(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        text: "Produk Berhasil\nDihapus ",
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StrukScreen extends StatelessWidget {
  final int strukId;
  final String pelanggan;
  final String metode;
  final List<Map<String, dynamic>> allDetails;

  const StrukScreen({
    super.key,
    required this.strukId,
    required this.pelanggan,
    required this.metode,
    required this.allDetails,
  });

  String formatRupiah(dynamic value) {
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(n);
  }

  String formatTanggal(dynamic value) {
    if (value == null) return '-';
    if (value is DateTime) return DateFormat('dd MMM yyyy').format(value);
    return DateFormat('dd MMM yyyy').format(DateTime.parse(value.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final totalHarga = allDetails.fold<num>(
        0, (sum, item) => sum + (num.tryParse(item['subtotal'].toString()) ?? 0));

    final tanggal = allDetails.isNotEmpty
        ? formatTanggal(allDetails.first['created_at'])
        : '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Struk Pembelian'), backgroundColor: Colors.brown),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tempest Store',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
              const SizedBox(height: 4),
              Text('Tanggal: $tanggal'),
              Text('Pelanggan: $pelanggan'),
              const Divider(thickness: 1),
              Expanded(
                child: allDetails.isEmpty
                    ? const Center(child: Text('Tidak ada produk di struk ini'))
                    : ListView.separated(
                        itemCount: allDetails.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = allDetails[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['namaproduk'] ?? '-'),
                            subtitle: Text('ID: ${item['produkid']}'),
                            trailing: Text(
                                '${item['jumlahproduk']}x - ${formatRupiah(item['subtotal'])}'),
                          );
                        },
                      ),
              ),
              const Divider(thickness: 1),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Metode: $metode'),
                Text(formatRupiah(totalHarga),
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              Center(
                  child: Text('Terima kasih telah berbelanja!',
                      style: TextStyle(color: Colors.grey.shade600))),
            ]),
          ),
        ),
      ),
    );
  }
}

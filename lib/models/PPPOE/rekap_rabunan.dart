import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class rekap_rabunan extends StatefulWidget {
  @override
  _rekap_rabunanState createState() => _rekap_rabunanState();
}

class _rekap_rabunanState extends State<rekap_rabunan> {
  List<dynamic> rekapData = [];
  String cabang = 'abel';
  int totalTagihan = 0;

  Future<void> fetchData() async {
    final response = await http.post(
      Uri.parse('http://aplikasi.bago.web.id/api/admin/ppoe_lunas.php'),
      body: {'cabang': cabang ?? ''},
    );

    if (response.statusCode == 200) {
      setState(() {
        rekapData = jsonDecode(response.body);
        calculateTotalTagihan();
      });
    } else {
      print('Failed to fetch data');
    }
  }

  Future<void> saveData() async {
    final url =
        Uri.parse('http://aplikasi.bago.web.id/api/admin/setoran_pppoe.php');
    final response = await http.post(
      url,
      body: {
        'tanggal_setor': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'jumlah_setoran': totalTagihan.toString(), // Konversi ke string
        'keterangan': 'abel',
      },
    );

    if (response.statusCode == 200) {
      print('Data berhasil disimpan');
    } else {
      print('Error: ${response.body}');
    }
  }

  Future<void> getSharedPrefData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cabang = prefs.getString('nama') ?? '';
    });
  }

  void calculateTotalTagihan() {
    int sum = 0;
    for (var rekap in rekapData) {
      sum += int.parse(rekap['tagihan']);
    }
    setState(() {
      totalTagihan = sum;
    });
  }

  void navigateToInvoicePage(
      String customerName, String month, double totalBill, String bulan) {}

  @override
  void initState() {
    super.initState();
    fetchData();
    getSharedPrefData();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
    final dateFormat = DateFormat('MM-yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Lunas Rabunan'),
        actions: [
          ElevatedButton(
            onPressed:
                saveData, // Memanggil fungsi saveData() ketika tombol ditekan
            child: Text('Simpan'), // Teks pada tombol
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Cabang: $cabang\nTotal Tagihan: ${numberFormat.format(totalTagihan)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 20,
                columns: <DataColumn>[
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Tagihan')),
                  DataColumn(label: Text('bulan')),
                  DataColumn(
                    label: Text('Status'),
                  ), // Set custom width for the Status column
                ],
                rows: rekapData.map((rekap) {
                  final DateTime tglMasuk = DateTime.parse(rekap['tgl_masuk']);
                  final formattedTglMasuk = dateFormat.format(tglMasuk);
                  final status = int.parse(rekap['status']);
                  Color statusColor = status == 1
                      ? Colors.green
                      : status == 3
                          ? Colors.blue
                          : Colors.black;

                  return DataRow(
                    cells: <DataCell>[
                      DataCell(GestureDetector(
                        onTap: () {
                          final id = rekap['id'];
                          final customerName = rekap['name'];
                          final totalBill =
                              int.parse(rekap['tagihan']).toDouble();
                          final month = formattedTglMasuk;

                          navigateToInvoicePage(customerName, month, totalBill,
                              formattedTglMasuk);
                        },
                        child: Text(rekap['name']),
                      )),
                      DataCell(Text(
                          numberFormat.format(int.parse(rekap['tagihan'])))),
                      DataCell(Text(formattedTglMasuk)),
                      DataCell(Text(
                        status == 1
                            ? 'Bayar'
                            : status == 3
                                ? 'Transfer'
                                : 'Unknown',
                        style: TextStyle(color: statusColor),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

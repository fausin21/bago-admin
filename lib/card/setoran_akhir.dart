import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import './korwil.dart';
import 'package:gojek_clone/network/network.dart';

class SetoranAkhir extends StatefulWidget {
  @override
  _SetoranAkhirState createState() => _SetoranAkhirState();
}

class _SetoranAkhirState extends State<SetoranAkhir> {
  List<dynamic> data = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final response = await http.get(Uri.parse(
        '${Network.Url}/api/admin/admin_baru/data_korwil.php'));
    if (response.statusCode == 200) {
      setState(() {
        data = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> addData(String id, String korwil, String noHp, String bulanan,
      String voucher, String pppoe, String total, String ket) async {
    final response = await http.post(
      Uri.parse('${Network.Url}/api/admin/admin_baru/add_data.php'),
      body: json.encode({
        'id': id,
        'korwil': korwil,
        'no_hp': noHp,
        'bulanan': bulanan,
        'voucher': voucher,
        'pppoe': pppoe,
        'total': total,
        'ket': ket,
      }),
    );

    if (response.statusCode == 200) {
      print('Success: ${response.body}');
      getData();
    } else {
      print('Error: ${response.body}');
      throw Exception('Failed to add data');
    }
  }

  String generateRandomId() {
    final random = Random();
    final id = random.nextInt(900) +
        100; // Generate a random number between 100 and 999
    return id.toString();
  }

  String formatRupiah(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
    return formatCurrency.format(amount);
  }

  void showAddDataDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController noHpController = TextEditingController();
    final TextEditingController bulananController = TextEditingController();
    final TextEditingController voucherController = TextEditingController();
    final TextEditingController pppoeController = TextEditingController();
    final TextEditingController totalController = TextEditingController();
    final TextEditingController ketController = TextEditingController();
    idController.text = generateRandomId();
    String selectedKorwil = 'mandati';
    final Map<String, String> korwilToHp = {
      'mandati': '6281238172616',
      'shp': '6281346765056',
      'plaosan': '6285257783826',
      'tito': '6285259359360',
      'abel': '6285330678337',
    };

    void updateTotal() {
      final bulanan = double.tryParse(bulananController.text) ?? 0;
      final voucher = double.tryParse(voucherController.text) ?? 0;
      final pppoe = double.tryParse(pppoeController.text) ?? 0;
      final total = bulanan + voucher + pppoe;
      totalController.text = formatRupiah(total);
      ketController.text = 'BL';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Data'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: idController,
                  decoration: InputDecoration(labelText: 'ID'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedKorwil,
                  decoration: InputDecoration(labelText: 'Korwil'),
                  items: korwilToHp.keys.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    selectedKorwil = newValue!;
                    noHpController.text = korwilToHp[selectedKorwil]!;
                  },
                ),
                TextField(
                  controller: noHpController,
                  decoration: InputDecoration(labelText: 'Nomer HP'),
                ),
                TextField(
                  controller: bulananController,
                  decoration: InputDecoration(labelText: 'Bulanan'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => updateTotal(),
                ),
                TextField(
                  controller: voucherController,
                  decoration: InputDecoration(labelText: 'Voucher'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => updateTotal(),
                ),
                TextField(
                  controller: pppoeController,
                  decoration: InputDecoration(labelText: 'PPPoE'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => updateTotal(),
                ),
                TextField(
                  controller: totalController,
                  decoration: InputDecoration(labelText: 'Total'),
                ),
                TextField(
                  controller: ketController,
                  decoration: InputDecoration(labelText: 'Keterangan'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                addData(
                  idController.text,
                  selectedKorwil,
                  noHpController.text,
                  bulananController.text,
                  voucherController.text,
                  pppoeController.text,
                  totalController.text,
                  ketController.text,
                );
                Navigator.of(context).pop();
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void showTagihan() {
    // arahkan ke KorwilListScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KorwilListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        title: Text(
          'DATA SETORAN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Total: ',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${formatCurrency(calculateTotal())}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Rincian',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (BuildContext context, int index) {
                String phoneNumber = data[index]['no_hp'];
                String message = 'ID Anda: ${data[index]['id']}\n'
                    'Cabang: ${data[index]['korwil']}\n'
                    'Voucher: ${formatCurrency(data[index]['voucher'])}\n'
                    'Bulanan: ${formatCurrency(data[index]['bulanan'])}\n'
                    'Total: ${formatCurrency(data[index]['total'])}';

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ID: ${data[index]['id']}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Korwil: ${data[index]['korwil']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nomer: ${data[index]['no_hp']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bulanan: ${formatCurrency(data[index]['bulanan'])}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Voucher: ${formatCurrency(data[index]['voucher'])}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'PPPoE: ${formatCurrency(data[index]['pppoe'])}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Total: ${formatCurrency(data[index]['total'])}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Keterangan: ${data[index]['ket'] ?? ''}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  launch(
                                      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
                                },
                                icon: Icon(Icons.message_rounded), // Icon pesan
                                label: Text('Hubungi via WA'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green, // Warna teks
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setAsLunas(data[index]['id']);
                                },
                                icon: Icon(
                                    Icons.check_circle_rounded), // Icon centang
                                label: Text('KlikLunas'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue, // Warna teks
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Data',
            onTap: () {
              showAddDataDialog();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.receipt),
            label: 'Show Tagihan',
            onTap: showTagihan,
          ),
        ],
      ),
    );
  }

  String formatCurrency(dynamic amount) {
    final formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    if (amount is String) {
      // Parse string to double if necessary
      double parsedAmount = double.tryParse(amount) ?? 0.0;
      return formatCurrency.format(parsedAmount);
    } else if (amount is double) {
      return formatCurrency.format(amount);
    } else {
      // Handle other cases gracefully
      return '';
    }
  }

  double calculateTotal() {
    double total = 0.0;
    for (var item in data) {
      // Use double.tryParse() to convert item['total'] to double
      double? totalValue = double.tryParse(item['total'] ?? '0.0');
      if (totalValue != null) {
        total += totalValue;
      }
    }
    return total;
  }

  Future<void> setAsLunas(String id) async {
    final response = await http.post(
      Uri.parse('${Network.Url}/api/admin/admin_baru/set_lunas.php'),
      body: json.encode({'id': id}),
    );

    if (response.statusCode == 200) {
      print('Success: ${response.body}');
      getData();
    } else {
      print('Error: ${response.body}');
      throw Exception('Failed to mark as paid');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserData {
  final String id;
  final String name;
  final String password;
  final String macAddress;
  final String profile;
  final String limitUptime;
  final String limitBytesTotal;
  final String uptime;
  final String bytesIn;
  final String bytesOut;
  final String packetsIn;
  final String packetsOut;
  final bool disabled;
  final String comment;

  UserData({
    required this.id,
    required this.name,
    required this.password,
    required this.macAddress,
    required this.profile,
    required this.limitUptime,
    required this.limitBytesTotal,
    required this.uptime,
    required this.bytesIn,
    required this.bytesOut,
    required this.packetsIn,
    required this.packetsOut,
    required this.disabled,
    required this.comment,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['.id'],
      name: json['name'],
      password: json['password'],
      // mengatasi mac adress null
      macAddress: json['mac-address'] ?? '0',

      profile: json['profile'],
      limitUptime: json['limit-uptime'],
      limitBytesTotal: json['limit-bytes-total'],
      uptime: json['uptime'],
      bytesIn: json['bytes-in'],
      bytesOut: json['bytes-out'],
      packetsIn: json['packets-in'],
      packetsOut: json['packets-out'],
      disabled: json['disabled'] == "true",
      comment: json['comment'],
    );
  }
}

class CekVoucher extends StatefulWidget {
  const CekVoucher({Key? key}) : super(key: key);

  @override
  _CekVoucherState createState() => _CekVoucherState();
}

class _CekVoucherState extends State<CekVoucher> {
  Future<UserData>? userData;
  final _controller = TextEditingController();
  bool hasPressedButton = false;
  Future<String?> fetchDataFromAPI(String macAddress) async {
    String apiUrl = "https://api.macvendors.com/$macAddress";

    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        return response.body; // Pastikan ini mengembalikan String
      } else {
        return "Not Found";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<UserData> fetchVoucherData(String voucher) async {
    final response = await http.get(
      Uri.parse(
        'http://aplikasi.bago.web.id/api/bago/cek_voucher.php?voucher=$voucher',
      ),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.isNotEmpty) {
        return UserData.fromJson(jsonResponse[0]);
      }
    }

    return UserData(
      id: '',
      name: '',
      password: '',
      macAddress: '',
      profile: '',
      limitUptime: '',
      limitBytesTotal: '',
      uptime: '',
      bytesIn: '',
      bytesOut: '',
      packetsIn: '',
      packetsOut: '',
      disabled: false,
      comment: '',
    );
  }

  void _handleButtonPress() {
    setState(() {
      hasPressedButton = true;
      userData = fetchVoucherData(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Voucher'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Masukkan Voucher',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userData = fetchVoucherData(_controller.text);

                  hasPressedButton = true;
                });
              },
              child: Text('Cari'),
            ),
            hasPressedButton
                ? FutureBuilder<UserData>(
                    future: userData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Sedang mencari data...',
                              style: TextStyle(fontSize: 20)),
                        );
                      } else if (snapshot.connectionState ==
                          ConnectionState.done) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final userData = snapshot.data!;

                        if (userData.id == '') {
                          return AlertDialog(
                            title: Text('Data tidak ada'),
                            content: Text(
                                'User dengan voucher tersebut tidak ditemukan.'),
                            actions: [
                              TextButton(
                                onPressed: () {},
                                child: Text('Coba cari lain'),
                              ),
                            ],
                          );
                        }

                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Merek Handphone',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              FutureBuilder<String?>(
                                future: fetchDataFromAPI(userData.macAddress),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasData) {
                                    return Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Vendor: ${snapshot.data}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Error: ${snapshot.error}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  } else {
                                    return SizedBox(); // Widget kosong jika tidak ada data
                                  }
                                },
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Data')),
                                    DataColumn(label: Text('Hasil')),
                                  ],
                                  rows: [
                                    DataRow(cells: [
                                      DataCell(Text('Masa Aktif')),
                                      DataCell(Text(userData.comment)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Name')),
                                      DataCell(Text(userData.name)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Password')),
                                      DataCell(Text(userData.password)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Mac Address')),
                                      DataCell(Text(userData.macAddress)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Profile')),
                                      DataCell(Text(userData.profile)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Limit Uptime')),
                                      DataCell(Text(userData.limitUptime)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Limit Bytes Total')),
                                      DataCell(Text(userData.limitBytesTotal)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Uptime')),
                                      DataCell(Text(userData.uptime)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Bytes In')),
                                      DataCell(Text(userData.bytesIn)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Bytes Out')),
                                      DataCell(Text(userData.bytesOut)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Packets In')),
                                      DataCell(Text(userData.packetsIn)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Packets Out')),
                                      DataCell(Text(userData.packetsOut)),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Disabled')),
                                      DataCell(
                                          Text(userData.disabled.toString())),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}

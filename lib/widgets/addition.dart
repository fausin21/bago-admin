import 'package:flutter/material.dart';
import 'package:gojek_clone/screens/aktif_pppoe.dart';
import 'package:gojek_clone/screens/non_pppoe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Addition extends StatefulWidget {
  const Addition({Key? key}) : super(key: key);

  @override
  State<Addition> createState() => _AdditionState();
}

class _AdditionState extends State<Addition> {
  int totalActive = 0;
  int totalInactive = 0;
  int totalConnections = 0;

  Future<void> fetchData() async {
    final response = await http
        .get(Uri.parse('http://aplikasi.bago.web.id/api/admin/ppoe_status.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalActive = data['total_active'];
        totalInactive = data['total_inactive'];
        totalConnections = data['total_connections'];
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: ListView(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NonAktifPppoe(),
                  ),
                );
                // Refresh data setelah kembali dari halaman NonAktifPppoe
                fetchData();
              },
              child: Container(
                width: 235,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.grey, blurRadius: 2),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NON AKTIF: $totalInactive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.7,
                        ),
                      ),
                      SizedBox(
                        child: Image.asset(
                          'assets/images/icon voucher.png',
                          scale: 2.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PppoeForm(),
                  ),
                );
                // Refresh data setelah kembali dari halaman PppoeForm
                fetchData();
              },
              child: Container(
                width: 235,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.grey, blurRadius: 2),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PPPOE AKTIF: $totalActive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.7,
                        ),
                      ),
                      SizedBox(
                        child: Image.asset(
                          'assets/images/icon gofood flat.png',
                          scale: 2.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Container(
              width: 235,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.grey, blurRadius: 2),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total PPPOE: $totalConnections',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.7,
                      ),
                    ),
                    SizedBox(
                      child: Image.asset(
                        'assets/images/promo.png',
                        scale: 2.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
          ],
        ),
      ),
    );
  }
}

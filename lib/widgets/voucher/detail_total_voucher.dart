import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:glassmorphism/glassmorphism.dart';

class DetailVoucherScreen extends StatefulWidget {
  final String daerah;
  final String namaDaerah;
  final List<dynamic> vouchers;

  const DetailVoucherScreen({
    Key? key,
    required this.daerah,
    required this.namaDaerah,
    required this.vouchers,
  }) : super(key: key);

  @override
  _DetailVoucherScreenState createState() => _DetailVoucherScreenState();
}

class _DetailVoucherScreenState extends State<DetailVoucherScreen> {
  List<dynamic> filteredVouchers = [];
  String searchQuery = '';
  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    filteredVouchers = widget.vouchers;
  }

  void filterVouchers(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredVouchers = widget.vouchers;
      } else {
        filteredVouchers = widget.vouchers.where((voucher) {
          final username = voucher['username'].toString().toLowerCase();
          final voucherCode = voucher['voucher'].toString().toLowerCase();
          final mac = voucher['komentar'].toString().toLowerCase();
          final tanggal = voucher['tanggal'].toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return username.contains(searchLower) ||
              voucherCode.contains(searchLower) ||
              mac.contains(searchLower) ||
              tanggal.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.purple[400]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              FadeInDown(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Detail Voucher ${widget.namaDaerah}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              FadeInDown(
                delay: Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 60,
                    borderRadius: 10,
                    blur: 20,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        onChanged: filterVouchers,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Cari username, voucher, tanggal, atau MAC...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FadeInUp(
                  delay: Duration(milliseconds: 400),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredVouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = filteredVouchers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 120,
                          borderRadius: 15,
                          blur: 20,
                          border: 2,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      voucher['username'] ?? '',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    Text(
                                      currencyFormat.format(voucher['harga']),
                                      style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: Colors.white70, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      '${voucher['tanggal']} ${voucher['waktu']}',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key,
                                        color: Colors.white70, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      voucher['voucher'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.computer,
                                        color: Colors.white70, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      voucher['komentar'] ?? '',
                                      style: TextStyle(color: Colors.white70),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

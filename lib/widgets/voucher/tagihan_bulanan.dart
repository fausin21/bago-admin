import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rekap_BAGO.dart';
import 'rekap_SENTUL.dart';
import 'ls_admin_voucher_bago.dart';
import 'ls_admin_voucher_sentul.dart';

class TagihanBulananForm extends StatefulWidget {
  @override
  _TagihanBulananFormState createState() => _TagihanBulananFormState();
}

class _TagihanBulananFormState extends State<TagihanBulananForm>
    with TickerProviderStateMixin {
  List<dynamic> tagihanList = [];
  List<dynamic> filteredTagihanList = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  String? cabang;
  String selectedCabang = 'Semua';
  List<String> cabangList = ['Semua', 'bago', 'sentul'];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    fetchTagihanData();
    setState(() {
      isLoading = true;
    });

    getSharedPreferencesData().then((data) {
      String? namaCabang = data;
      if (namaCabang != null) {
        if (namaCabang == 'indra') {
          cabang = 'bago';
        } else if (namaCabang == 'MULYADI') {
          cabang = 'sentul';
        }
      }

      if (cabang != null) {
        fetchTagihanData().then((data) {
          setState(() {
            tagihanList = data;
            filteredTagihanList = data;
            isLoading = false;
          });
          _animationController.forward();
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchTagihanData() async {
    final response = await http.post(
      Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/admin_baru/tagihan_voucher.php'),
    );
    if (response.statusCode == 200) {
      setState(() {
        tagihanList = json.decode(response.body);
        filteredTagihanList = tagihanList;
        isLoading = false;
      });
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch tagihan data');
    }
  }

  Future<String?> getSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama');
  }

  void filterTagihanList(String query) {
    List<dynamic> tempList = [];
    tempList.addAll(tagihanList);
    if (query.isNotEmpty || selectedCabang != 'Semua') {
      List<dynamic> filteredList = [];
      tempList.forEach((tagihan) {
        bool matchQuery = query.isEmpty ||
            tagihan['user'].toLowerCase().contains(query.toLowerCase());
        bool matchCabang = selectedCabang == 'Semua' ||
            tagihan['cabang']?.toString().toLowerCase() ==
                selectedCabang.toLowerCase();

        if (matchQuery && matchCabang) {
          filteredList.add(tagihan);
        }
      });
      setState(() {
        filteredTagihanList = filteredList;
      });
    } else {
      setState(() {
        filteredTagihanList = tempList;
      });
    }
  }

  double calculateTotal() {
    double total = 0;
    for (var tagihan in filteredTagihanList) {
      if (tagihan['total'] != null) {
        total += double.parse(tagihan['total'].toString());
      }
    }
    return total;
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  Future<void> payBill(String id) async {
    try {
      String? user = await getSharedPreferencesData();
      print("DEBUG: Paying bill $id with user: $user");

      final url = 'http://aplikasi.bago.web.id/api/admin/bayar.php?kode=$id';

      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Pembayaran berhasil!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception('Payment failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Pembayaran gagal!'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void showPaymentDialog(int id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        int index = filteredTagihanList
            .indexWhere((tagihan) => tagihan['id_tagihan'] == id.toString());
        if (index != -1) {
          String user = filteredTagihanList[index]['user'];
          String tagihan = filteredTagihanList[index]['id_tagihan'];
          String total = formatCurrency(
              double.parse(filteredTagihanList[index]['total'].toString()));

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 16,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey[50]!],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.payment_rounded,
                        color: Colors.green[600], size: 32),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('ID Tagihan', tagihan),
                        SizedBox(height: 8),
                        _buildInfoRow('Nama Pengguna', user),
                        SizedBox(height: 8),
                        _buildInfoRow('Total Tagihan', total),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Batal'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await payBill(id.toString());
                            fetchTagihanData().then((data) {
                              setState(() {
                                tagihanList = data;
                                filteredTagihanList = data;
                              });
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Bayar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Tagihan dengan id $id tidak ditemukan.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: Text('OK'),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Tagihan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  formatCurrency(calculateTotal()),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${filteredTagihanList.length} tagihan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) => filterTagihanList(value),
            decoration: InputDecoration(
              hintText: 'Cari nama pengguna...',
              prefixIcon: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.search, color: Colors.blue[600]),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCabang,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                items: cabangList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'Semua'
                              ? Icons.all_inclusive
                              : Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          value == 'Semua'
                              ? 'Semua Cabang'
                              : value.toUpperCase(),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCabang = newValue!;
                    filterTagihanList(searchController.text);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagihanCard(dynamic tagihan, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              showPaymentDialog(int.parse(tagihan['id_tagihan'].toString())),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[400]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          tagihan['user'].toString().isNotEmpty
                              ? tagihan['user'][0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tagihan['user'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_month,
                                  size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                '${tagihan['bulan']}/${tagihan['tahun']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCabangColor(tagihan['cabang']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tagihan['cabang']?.toString().toUpperCase() ??
                                      'N/A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(
                              double.parse(tagihan['total'].toString())),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Belum Bayar',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCabangColor(String? cabang) {
    switch (cabang?.toLowerCase()) {
      case 'bago':
        return Colors.red[600]!;
      case 'sentul':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _navigateToPage(BuildContext context, String title, Widget page) {
    // Use push so the user can press back to return to this Tagihan page.
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // title removed as requested
        title: SizedBox.shrink(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                _navigateToPage(context, 'SENTUL ADMIN',
                    LsAdminVoucherSentul(cabang: 'sentul'));
              },
              child: Text('SENTUL ADMIN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
                backgroundColor: Colors.teal[50],
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                minimumSize: Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                _navigateToPage(
                    context, 'BAGO ADMIN', LsAdminVoucherBago(cabang: 'bago'));
              },
              child: Text('BAGO ADMIN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[800],
                backgroundColor: Colors.orange[50],
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                minimumSize: Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                _navigateToPage(
                    context, 'SENTUL', Rekap_sentul(cabang: 'sentul'));
              },
              child: Text('SENTUL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[600],
                backgroundColor: Colors.purple[50],
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                minimumSize: Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                _navigateToPage(
                    context, 'BAGO', RekapBagoVoucher(cabang: 'bago'));
              },
              child: Text('BAGO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
                backgroundColor: Colors.red[50],
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                minimumSize: Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue[600]),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data tagihan...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () => fetchTagihanData(),
                color: Colors.blue[600],
                child: Column(
                  children: [
                    _buildStatsCard(),
                    _buildSearchAndFilter(),
                    Expanded(
                      child: filteredTagihanList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada tagihan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Semua tagihan sudah lunas',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: 16),
                              itemCount: filteredTagihanList.length,
                              itemBuilder: (context, index) {
                                return _buildTagihanCard(
                                    filteredTagihanList[index], index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

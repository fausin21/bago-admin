import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gojek_clone/models/PPPOE/ls_admin_bago.dart';
import 'package:gojek_clone/models/PPPOE/ls_admin_sentul.dart';
import 'package:gojek_clone/models/PPPOE/rekap_bago.dart';
import 'package:gojek_clone/models/PPPOE/sentul_rekap.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class PppoePage extends StatefulWidget {
  const PppoePage({Key? key}) : super(key: key);

  @override
  State<PppoePage> createState() => _PppoePageState();
}

class _PppoePageState extends State<PppoePage> with TickerProviderStateMixin {
  List<dynamic> pppoeList = [];
  List<dynamic> paketList = [];
  List<String> teknisiList = ['Semua'];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  int totalTagihan = 0;
  String? teknisi_name;
  String? teknisi_name_display;
  String selectedBranch = 'Semua';
  String selectedTeknisi = 'Semua';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id');
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchData();
    fetchPaket();
    getTeknisiName();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getTeknisiName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      teknisi_name = prefs.getString('nama');
      teknisi_name_display = prefs.getString('nama');
    });
  }

  Future<void> fetchPaket() async {
    try {
      final url = 'http://aplikasi.bago.web.id/api/bago/bago_baru/paket.php';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          paketList = json.decode(response.body);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data paket: $e');
    }
  }

  void _updateTotalTagihan() {
    totalTagihan = filteredPppoeList.fold(0, (sum, item) {
      return sum + int.parse(item['tagihan'].replaceAll(RegExp(r'[^\d]'), ''));
    });
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teknisi_name = prefs.getString('nama');
    String id_teknisi;

    if (teknisi_name == "MULYADI") {
      id_teknisi = "2";
    } else if (teknisi_name == "bago") {
      id_teknisi = "1";
    } else {
      id_teknisi = "0";
    }

    try {
      final url =
          'http://aplikasi.bago.web.id/api/admin/pppoe_belum.php?id=$id_teknisi';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pppoeList = data;

          // Extract unique teknisi names for filter
          Set<String> uniqueTeknisi = {'Semua'};
          for (var item in data) {
            if (item['teknisi_name'] != null &&
                item['teknisi_name'].toString().isNotEmpty) {
              uniqueTeknisi.add(item['teknisi_name'].toString());
            }
          }
          teknisiList = uniqueTeknisi.toList();

          _updateTotalTagihan();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> showDialogAndPay(pppoeData) async {
    TextEditingController noHpController = TextEditingController();
    noHpController.text = pppoeData['no_hp'] ?? '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Konfirmasi Pembayaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('User ID', pppoeData['id'], Icons.person),
                      _buildInfoRow(
                          'Username', pppoeData['user'], Icons.account_circle),
                      _buildInfoRow(
                          'Bulan', pppoeData['bulan'], Icons.calendar_month),
                      _buildInfoRow(
                          'Tahun', pppoeData['tahun'], Icons.calendar_today),
                      Divider(color: Colors.grey[300]),
                      _buildInfoRow(
                        'Tagihan',
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                        ).format(int.parse(pppoeData['tagihan']
                            .replaceAll(RegExp(r'[^\d]'), ''))),
                        Icons.monetization_on,
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: noHpController,
                  decoration: InputDecoration(
                    labelText: 'Nomor HP',
                    hintText: 'Masukkan nomor HP...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.phone, color: Colors.blue[600]),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.blue[600]!, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Batal'),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.payment, size: 20),
              label: Text('Bayar Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 2,
              ),
              onPressed: () async {
                if (noHpController.text.isEmpty) {
                  _showErrorSnackBar('Nomor HP wajib diisi');
                  return;
                }

                String id = pppoeData['id'].toString();

                // Ambil nama langsung dari SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? namaLogin = prefs.getString('nama');

                // Jika login sebagai fausin (admin), status jadi LS_ADMIN
                String payUrl;
                if (namaLogin != null &&
                    namaLogin.trim().toLowerCase() == "fausin") {
                  payUrl =
                      'http://aplikasi.bago.web.id/api/admin/admin_baru/bayar_pppoe.php?kode=$id&sts=LS_ADMIN';
                } else {
                  payUrl =
                      'http://aplikasi.bago.web.id/api/bago/bago_baru/bayar_pppoe.php?kode=$id';
                }

                try {
                  final payResponse = await http.get(Uri.parse(payUrl));
                  if (payResponse.statusCode == 200) {
                    _showSuccessSnackBar('Pembayaran berhasil diproses');
                    fetchData();
                  }
                } catch (e) {
                  _showErrorSnackBar('Pembayaran gagal: $e');
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isHighlight ? Colors.red[600] : Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? Colors.red[600] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.red[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Tagihan Belum Dibayar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(totalTagihan),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                  'Total User', '${filteredPppoeList.length}', Icons.people),
              _buildStatItem(
                  'Teknisi', teknisi_name_display ?? '-', Icons.engineering),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic pppoe) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final tagihanValue =
        int.parse(pppoe['tagihan'].replaceAll(RegExp(r'[^\d]'), ''));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showDialogAndPay(pppoe),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red[100],
                      radius: 24,
                      child: Icon(
                        Icons.person,
                        color: Colors.red[600],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pppoe['user'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${pppoe['id']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        'Belum Bayar',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(
                          'Tagihan',
                          currencyFormatter.format(tagihanValue),
                          Icons.monetization_on,
                          Colors.red[600]!),
                      _buildDetailItem(
                          'Periode',
                          '${pppoe['bulan']} ${pppoe['tahun']}',
                          Icons.calendar_today,
                          Colors.blue[600]!),
                    ],
                  ),
                ),
                if (pppoe['teknisi_name'] != null &&
                    pppoe['teknisi_name'].isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.engineering,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'Teknisi: ${pppoe['teknisi_name']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeknisiFilter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedTeknisi,
        decoration: InputDecoration(
          labelText: 'Filter Teknisi',
          prefixIcon: Icon(Icons.engineering, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: teknisiList.map((String teknisi) {
          return DropdownMenuItem<String>(
            value: teknisi,
            child: Text(teknisi),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedTeknisi = newValue ?? 'Semua';
            _updateTotalTagihan();
          });
        },
      ),
    );
  }

  List<dynamic> get filteredPppoeList {
    return pppoeList.where((pppoe) {
      final searchMatch = searchController.text.isEmpty ||
          pppoe['user']
              .toLowerCase()
              .contains(searchController.text.toLowerCase()) ||
          pppoe['id'].toString().contains(searchController.text);

      final teknisiMatch = selectedTeknisi == 'Semua' ||
          (pppoe['teknisi_name'] != null &&
              pppoe['teknisi_name'].toString() == selectedTeknisi);

      return searchMatch && teknisiMatch;
    }).toList();
  }

  Future<void> _confirmNavigasi({
    required String judul,
    required Color warna,
    required IconData ikon,
    required Widget halaman,
  }) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Loading',
      barrierColor: Colors.black38,
      transitionDuration: Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnim,
          child: FadeTransition(
            opacity: anim1,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: warna.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: warna.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ikon, color: warna, size: 36),
                      ),
                      SizedBox(height: 12),
                      Text(
                        judul,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: warna,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(warna),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    await Future.delayed(Duration(milliseconds: 600));

    if (mounted) {
      Navigator.pop(context); // tutup overlay
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => halaman),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tagihan Belum Dibayar',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () => _confirmNavigasi(
                judul: 'SENTUL ADMIN',
                warna: Colors.teal[600]!,
                ikon: Icons.admin_panel_settings,
                halaman: LsAdminSentul(),
              ),
              child: Text('SENTUL ADMIN', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () => _confirmNavigasi(
                judul: 'BAGO ADMIN',
                warna: Colors.orange[700]!,
                ikon: Icons.admin_panel_settings,
                halaman: LsAdminBago(),
              ),
              child: Text('BAGO ADMIN', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () => _confirmNavigasi(
                judul: 'SENTUL',
                warna: Colors.purple[600]!,
                ikon: Icons.area_chart,
                halaman: RekapSentul(),
              ),
              child: Text('SENTUL', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => _confirmNavigasi(
                judul: 'BAGO',
                warna: Colors.red[600]!,
                ikon: Icons.area_chart,
                halaman: RekapBago(),
              ),
              child: Text('BAGO', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: fetchData,
          child: Column(
            children: [
              _buildStatsCard(),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari username atau ID...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                _updateTotalTagihan();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() {
                    _updateTotalTagihan();
                  }),
                ),
              ),
              _buildTeknisiFilter(),
              SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.red[600]),
                            SizedBox(height: 16),
                            Text(
                              'Memuat data tagihan...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : filteredPppoeList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  searchController.text.isNotEmpty ||
                                          selectedTeknisi != 'Semua'
                                      ? 'Tidak ada data yang sesuai dengan filter'
                                      : 'Tidak ada tagihan yang belum dibayar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPppoeList.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(filteredPppoeList[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchData,
        backgroundColor: Colors.red[600],
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh Data',
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gojek_clone/network/network.dart';

class KorwilData {
  final String id;
  final String korwil;
  final String noHp;
  final double bulanan;
  final double voucher;
  final double pppoe;
  final double total;
  final String ket;

  KorwilData({
    required this.id,
    required this.korwil,
    required this.noHp,
    required this.bulanan,
    required this.voucher,
    required this.pppoe,
    required this.total,
    required this.ket,
  });

  factory KorwilData.fromJson(Map<String, dynamic> json) {
    return KorwilData(
      id: json['id'],
      korwil: json['korwil'],
      noHp: json['no_hp'],
      bulanan: double.parse(json['bulanan']),
      voucher: double.parse(json['voucher']),
      pppoe: double.parse(json['pppoe']),
      total: double.parse(json['total']),
      ket: json['ket'],
    );
  }
}

class KorwilListScreen extends StatefulWidget {
  @override
  _KorwilListScreenState createState() => _KorwilListScreenState();
}

class _KorwilListScreenState extends State<KorwilListScreen>
    with TickerProviderStateMixin {
  late Future<List<KorwilData>> _futureKorwilData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  List<KorwilData> _allData = [];
  List<KorwilData> _filteredData = [];
  bool _isLoading = false;
  String _sortBy = 'korwil'; // korwil, total, bulanan, voucher

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeLocale();
    _refreshData();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await fetchKorwilData();
      setState(() {
        _allData = data;
        _filteredData = data;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: _refreshData,
          ),
        ),
      );
    }
  }

  Future<List<KorwilData>> fetchKorwilData() async {
    final response = await http.get(Uri.parse(
        '${Network.Url}/api/admin/admin_baru/tampilkan_korwil.php'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => KorwilData.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load korwil data');
    }
  }

  void _filterData(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredData = _allData;
      } else {
        _filteredData = _allData.where((data) {
          return data.korwil.toLowerCase().contains(query.toLowerCase()) ||
              data.id.toLowerCase().contains(query.toLowerCase()) ||
              data.noHp.contains(query);
        }).toList();
      }
    });
  }

  void _sortData(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'korwil':
          _filteredData.sort((a, b) => a.korwil.compareTo(b.korwil));
          break;
        case 'total':
          _filteredData.sort((a, b) => b.total.compareTo(a.total));
          break;
        case 'bulanan':
          _filteredData.sort((a, b) => b.bulanan.compareTo(a.bulanan));
          break;
        case 'voucher':
          _filteredData.sort((a, b) => b.voucher.compareTo(a.voucher));
          break;
      }
    });
  }

  void sendMessage(KorwilData data) async {
    String phoneNumber = data.noHp.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneNumber.startsWith('62')) {
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '62' + phoneNumber.substring(1);
      } else {
        phoneNumber = '62' + phoneNumber;
      }
    }

    String currentDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    String currentTime = DateFormat('HH:mm', 'id_ID').format(DateTime.now());

    String message = '''
🏢 *LAPORAN KEUANGAN KORWIL*
📅 Tanggal: $currentDate
⏰ Waktu: $currentTime WIB

👤 *INFORMASI KORWIL*
🆔 ID Korwil: ${data.id}
📍 Nama Korwil: ${data.korwil}
📱 No. HP: ${data.noHp}

💰 *RINCIAN KEUANGAN*
📊 Pendapatan Bulanan: ${formatCurrency(data.bulanan)}
🎫 Pendapatan Voucher: ${formatCurrency(data.voucher)}
🌐 Pendapatan PPPoE: ${formatCurrency(data.pppoe)}
💵 *TOTAL PENDAPATAN: ${formatCurrency(data.total)}*

📝 *KETERANGAN*
${data.ket.isNotEmpty ? data.ket : 'Tidak ada keterangan khusus'}

━━━━━━━━━━━━━━━━━━━━━━━━
🏢 BAGO.NET - Network Provider
📞 Hubungi admin untuk informasi lebih lanjut
━━━━━━━━━━━━━━━━━━━━━━━━

*Pesan ini dikirim secara otomatis dari sistem*
''';

    String url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesan WhatsApp berhasil dikirim ke ${data.korwil}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double calculateTotal(List<KorwilData> data) {
    return data.fold(0.0, (sum, item) => sum + item.total);
  }

  double calculateAverage(List<KorwilData> data) {
    if (data.isEmpty) return 0.0;
    return calculateTotal(data) / data.length;
  }

  String formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Korwil',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_filteredData.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
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
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Pendapatan',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formatCurrency(calculateTotal(_filteredData)),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Rata-rata',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formatCurrency(calculateAverage(_filteredData)),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _filterData,
                decoration: InputDecoration(
                  hintText: 'Cari korwil, ID, atau nomor HP...',
                  prefixIcon:
                      Icon(Icons.search_rounded, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              onSelected: _sortData,
              icon: Icon(Icons.sort_rounded, color: Colors.grey[700]),
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'korwil', child: Text('Urutkan: Nama Korwil')),
                PopupMenuItem(
                    value: 'total', child: Text('Urutkan: Total Tertinggi')),
                PopupMenuItem(
                    value: 'bulanan',
                    child: Text('Urutkan: Bulanan Tertinggi')),
                PopupMenuItem(
                    value: 'voucher',
                    child: Text('Urutkan: Voucher Tertinggi')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKorwilCard(KorwilData data, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      data.korwil.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.korwil,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge_rounded,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            'ID: ${data.id}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    formatCurrency(data.total),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Contact Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    data.noHp,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Financial Details
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                    'Bulanan',
                    formatCurrency(data.bulanan),
                    Icons.calendar_month_rounded,
                    Colors.blue[600]!,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialItem(
                    'Voucher',
                    formatCurrency(data.voucher),
                    Icons.local_offer_rounded,
                    Colors.purple[600]!,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialItem(
                    'PPPoE',
                    formatCurrency(data.pppoe),
                    Icons.router_rounded,
                    Colors.orange[600]!,
                  ),
                ),
              ],
            ),

            if (data.ket.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_rounded,
                            size: 16, color: Colors.amber[700]),
                        SizedBox(width: 6),
                        Text(
                          'Keterangan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      data.ket,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => sendMessage(data),
                icon: Icon(Icons.send_rounded, size: 20),
                label: Text('Kirim Laporan via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Data Korwil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data korwil...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildStatisticsCard(),
                  _buildSearchAndSort(),
                  SizedBox(height: 8),
                  Expanded(
                    child: _filteredData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Tidak ada data korwil'
                                      : 'Tidak ada hasil untuk "$_searchQuery"',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                              padding: EdgeInsets.only(bottom: 16),
                              itemCount: _filteredData.length,
                              itemBuilder: (context, index) {
                                return _buildKorwilCard(
                                    _filteredData[index], index);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

class Rekap_sentul extends StatefulWidget {
  final String? cabang;
  Rekap_sentul({this.cabang});

  @override
  _Rekap_sentulState createState() => _Rekap_sentulState();
}

class _Rekap_sentulState extends State<Rekap_sentul>
    with TickerProviderStateMixin {
  List<dynamic> rekapList = [];
  String? cabang;
  TextEditingController searchController = TextEditingController();
  int totalJumlah = 0;
  List<dynamic> filteredList = [];
  bool isLoading = false;
  String selectedPeriod = 'bulan_ini';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String? errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _initializeLocale();
    _initializeData();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _setCurrentMonth();
    _refreshData();
    getSharedPreferencesData().then((data) {
      String? namaCabang = data;
      if (namaCabang != null) {
        if (namaCabang == 'indra') {
          cabang = 'bago';
        } else if (namaCabang == 'MULYADI') {
          cabang = 'sentul';
        }
        _refreshData();
      }
    });
  }

  void _setCurrentMonth() {
    DateTime now = DateTime.now();
    setState(() {
      selectedStartDate = DateTime(now.year, now.month, 1);
      selectedEndDate = DateTime(now.year, now.month + 1, 0);
      selectedPeriod = 'bulan_ini';
    });
  }

  void _setPreviousMonth() {
    DateTime now = DateTime.now();
    DateTime previousMonth = DateTime(now.year, now.month - 1, 1);
    setState(() {
      selectedStartDate = previousMonth;
      selectedEndDate =
          DateTime(previousMonth.year, previousMonth.month + 1, 0);
      selectedPeriod = 'bulan_lalu';
    });
    filterList(searchController.text);
  }

  void _setThisMonth() {
    _setCurrentMonth();
    filterList(searchController.text);
  }

  Future<List<dynamic>> fetchRekapData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://aplikasi.bago.web.id/api/bago/bago_baru/taginan_voucher_lunas.php?cabang=${widget.cabang}'),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        // Handle different response structures
        if (decodedData is List) {
          return decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          return decodedData['data'] as List<dynamic>;
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to fetch rekap data: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await fetchRekapData();
      setState(() {
        rekapList = data;
        filterList(searchController.text);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
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

  Future<String?> getSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama');
  }

  void calculateTotal() {
    int total = 0;
    for (var data in filteredList) {
      // Use 'total' field as per the JSON structure provided
      String totalStr = data['total']?.toString() ?? '0';
      int amount = int.tryParse(totalStr) ?? 0;
      total += amount;
    }
    setState(() {
      totalJumlah = total;
    });
  }

  void filterList(String query) {
    setState(() {
      if (rekapList.isEmpty) {
        filteredList = [];
      } else {
        filteredList = rekapList.where((data) {
          // Safe access to user field
          String user = data['user']?.toString() ?? '';
          bool matchesSearch = user.toLowerCase().contains(query.toLowerCase());

          // If we have date filtering enabled and tgl_bayar exists
          if (selectedStartDate != null &&
              selectedEndDate != null &&
              data['tgl_bayar'] != null) {
            try {
              DateTime paymentDate = DateTime.parse(data['tgl_bayar']);
              bool matchesDateRange = paymentDate.isAfter(
                      selectedStartDate!.subtract(Duration(days: 1))) &&
                  paymentDate.isBefore(selectedEndDate!.add(Duration(days: 1)));
              return matchesSearch && matchesDateRange;
            } catch (e) {
              // If date parsing fails, just use search filter
              return matchesSearch;
            }
          }

          return matchesSearch;
        }).toList();
      }
      calculateTotal();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year, 1, 1),
      lastDate: DateTime(DateTime.now().year, 12, 31),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        selectedPeriod = 'custom';
        filterList(searchController.text);
      });
    }
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getPeriodText() {
    final now = DateTime.now();
    if (selectedPeriod == 'bulan_ini') {
      // Show full month name and current year, e.g. "Februari 2026"
      return DateFormat('MMMM yyyy', 'id_ID').format(now);
    } else if (selectedPeriod == 'bulan_lalu') {
      final prev = DateTime(now.year, now.month - 1, 1);
      return DateFormat('MMMM yyyy', 'id_ID').format(prev);
    } else if (selectedStartDate != null && selectedEndDate != null) {
      return '${DateFormat('dd MMM', 'id_ID').format(selectedStartDate!)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(selectedEndDate!)}';
    }
    return 'Pilih Periode';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Rekap Sentul',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Stats Card
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.purple[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
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
                                'Total Setoran',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatCurrency(totalJumlah),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 24 : 20,
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
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getPeriodText(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Period Selection
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPeriodButton(
                        'Bulan Ini',
                        selectedPeriod == 'bulan_ini',
                        _setThisMonth,
                        Icons.today_rounded,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildPeriodButton(
                        'Bulan Lalu',
                        selectedPeriod == 'bulan_lalu',
                        _setPreviousMonth,
                        Icons.history_rounded,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildPeriodButton(
                        'Custom',
                        selectedPeriod == 'custom',
                        () => _selectDateRange(context),
                        Icons.date_range_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: EdgeInsets.all(16),
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
                child: TextField(
                  controller: searchController,
                  onChanged: filterList,
                  decoration: InputDecoration(
                    hintText: 'Cari pengguna...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              // Debug Info (only show in debug mode)

              // Data List
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.purple[600]!),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Memuat data...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorMessage != null
                        ? _buildErrorState()
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            color: Colors.purple[600],
                            child: filteredList.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: filteredList.length,
                                    itemBuilder: (context, index) {
                                      return _buildDataCard(
                                          filteredList[index], index);
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

  Widget _buildPeriodButton(
      String text, bool isSelected, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple[600] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple[600]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(dynamic data, int index) {
    // Handle the actual JSON structure provided by user
    final amount = int.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final monthlyFee = int.tryParse(data['t_bulan']?.toString() ?? '0') ?? 0;
    final voucherFee = int.tryParse(data['t_voucher']?.toString() ?? '0') ?? 0;
    final month = data['bulan']?.toString() ?? '';
    final year = data['tahun']?.toString() ?? '';
    final userName = data['user']?.toString() ?? 'Unknown User';
    final idTagihan = data['id_tagihan']?.toString() ?? '';

    DateTime? paymentDate;
    try {
      paymentDate =
          data['tgl_bayar'] != null ? DateTime.parse(data['tgl_bayar']) : null;
    } catch (e) {
      paymentDate = null;
    }

    // Get month name in Indonesian
    String getMonthName(String monthNumber) {
      if (monthNumber.isEmpty) return '';
      final months = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      int monthInt = int.tryParse(monthNumber) ?? 0;
      return monthInt > 0 && monthInt <= 12 ? months[monthInt] : monthNumber;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[400]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            month.isNotEmpty
                                ? Icons.calendar_month_rounded
                                : Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            month.isNotEmpty
                                ? '${getMonthName(month)} $year'
                                : 'Sentul',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (idTagihan.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$idTagihan',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Total Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            amount > 0 ? Colors.green[600] : Colors.orange[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            amount > 0 ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amount > 0 ? 'Lunas' : 'Belum Bayar',
                        style: TextStyle(
                          fontSize: 10,
                          color: amount > 0
                              ? Colors.green[600]
                              : Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Show payment details if we have detailed data
            if (monthlyFee > 0 || voucherFee > 0 || paymentDate != null) ...[
              SizedBox(height: 16),

              // Payment Details
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Fee breakdown
                    Row(
                      children: [
                        if (monthlyFee > 0) ...[
                          Expanded(
                            child: _buildDetailItem(
                              'Tagihan Bulanan',
                              _formatCurrency(monthlyFee),
                              Icons.receipt_long_rounded,
                              Colors.blue[600]!,
                            ),
                          ),
                          if (voucherFee > 0) SizedBox(width: 12),
                        ],
                        if (voucherFee > 0) ...[
                          Expanded(
                            child: _buildDetailItem(
                              'Biaya Voucher',
                              _formatCurrency(voucherFee),
                              Icons.local_offer_rounded,
                              Colors.purple[600]!,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Payment date
                    if (paymentDate != null) ...[
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Dibayar: ${DateFormat('dd MMM yyyy', 'id_ID').format(paymentDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
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

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        children: [
          SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  rekapList.isEmpty ? 'Tidak ada data' : 'Tidak ada hasil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  rekapList.isEmpty
                      ? 'Belum ada transaksi tersedia'
                      : 'Tidak ada data yang sesuai dengan filter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: Icon(Icons.refresh_rounded),
                  label: Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage ?? 'Gagal memuat data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

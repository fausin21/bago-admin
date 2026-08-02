import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class LsAdminVoucherBago extends StatefulWidget {
  final String? cabang;

  LsAdminVoucherBago({this.cabang});

  @override
  _LsAdminVoucherBagoState createState() => _LsAdminVoucherBagoState();
}

class _LsAdminVoucherBagoState extends State<LsAdminVoucherBago>
    with TickerProviderStateMixin {
  List<dynamic> rekapList = [];
  String? cabang;
  TextEditingController searchController = TextEditingController();
  int totalJumlah = 0;
  List<dynamic> filteredList = [];
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  int currentYear = DateTime.now().year;
  bool isLoading = false;
  String selectedPeriod = 'bulan_ini';

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
    final response = await http.get(
      Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/tagihan_voucher_ls_admin.php?cabang=bago'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch rekap data');
    }
  }

  void calculateTotal() {
    int total = 0;
    for (var data in filteredList) {
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
      if (selectedStartDate == null || selectedEndDate == null) {
        filteredList = [];
      } else {
        filteredList = rekapList.where((data) {
          bool matchesSearch =
              data['user'].toLowerCase().contains(query.toLowerCase());

          DateTime paymentDate = DateTime.parse(data['tgl_bayar']);
          bool matchesDateRange = paymentDate
                  .isAfter(selectedStartDate!.subtract(Duration(days: 1))) &&
              paymentDate.isBefore(selectedEndDate!.add(Duration(days: 1)));
          return matchesSearch && matchesDateRange;
        }).toList();
      }
      calculateTotal();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(currentYear, 1, 1),
      lastDate: DateTime(currentYear, 12, 31),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange[600]!,
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
    if (selectedPeriod == 'bulan_ini') {
      return 'Bulan Ini';
    } else if (selectedPeriod == 'bulan_lalu') {
      return 'Bulan Lalu';
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
          'LS Admin Voucher BAGO',
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
                    colors: [Colors.orange[600]!, Colors.orange[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
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
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
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

              // Data List
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange[600]!),
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
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: Colors.orange[600],
                        child: filteredList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
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
          color: isSelected ? Colors.orange[600] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
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
    final paymentDate = data['tgl_bayar'] != null
        ? DateTime.parse(data['tgl_bayar'])
        : DateTime.now();
    final totalAmount = int.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final monthlyFee = int.tryParse(data['t_bulan']?.toString() ?? '0') ?? 0;
    final voucherFee = int.tryParse(data['t_voucher']?.toString() ?? '0') ?? 0;
    final month = data['bulan']?.toString() ?? '';
    final year = data['tahun']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';

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

    // Determine status color and text
    Color statusColor;
    String statusText;

    if (status == 'LS_ADMIN') {
      statusColor = Colors.orange[600]!;
      statusText = 'LS Admin';
    } else if (totalAmount > 0) {
      statusColor = Colors.green[600]!;
      statusText = 'Lunas';
    } else {
      statusColor = Colors.red[600]!;
      statusText = 'Belum Bayar';
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
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      data['user'].toString().substring(0, 1).toUpperCase(),
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
                        data['user'],
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
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${getMonthName(month)} $year',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                      _formatCurrency(totalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

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
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Tagihan Bulanan',
                          _formatCurrency(monthlyFee),
                          Icons.receipt_long_rounded,
                          Colors.blue[600]!,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          'Biaya Voucher',
                          _formatCurrency(voucherFee),
                          Icons.local_offer_rounded,
                          Colors.purple[600]!,
                        ),
                      ),
                    ],
                  ),
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
                          'Dibayar: ${DateFormat('dd MMM yyyy', 'id_ID').format(paymentDate)}',
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
              ),
            ),
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
    return Center(
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
            'Tidak ada data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

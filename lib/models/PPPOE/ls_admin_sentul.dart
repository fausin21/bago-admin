import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LsAdminSentul extends StatefulWidget {
  @override
  _LsAdminSentulState createState() => _LsAdminSentulState();
}

class _LsAdminSentulState extends State<LsAdminSentul>
    with TickerProviderStateMixin {
  List<dynamic> rekapData = [];
  List<dynamic> filteredData = [];
  String cabang = 'SENTUL';
  double totalTagihan = 0;
  String selectedMonth = '';
  String selectedYear = '';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> availableMonths = [
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

  late List<String> availableYears;

  @override
  void initState() {
    super.initState();

    // Generate tahun otomatis dari 3 tahun yang lalu sampai tahun ini
    int currentYear = DateTime.now().year;
    availableYears = List.generate(
      4,
      (index) => (currentYear - 3 + index).toString(),
    );

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set default ke bulan dan tahun ini
    DateTime now = DateTime.now();
    selectedMonth = availableMonths[now.month - 1];
    selectedYear = now.year.toString();

    fetchData();
    getSharedPrefData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://aplikasi.bago.web.id/api/admin/admin_baru/pppoe_ls_admin.php?id=2'),
      );

      if (response.statusCode == 200) {
        setState(() {
          var allData = jsonDecode(response.body);
          rekapData = allData.map((item) {
            DateTime tglBayar = DateTime.parse(item['tgl_bayar']);
            item['bulan'] = tglBayar.month.toString();
            item['tahun'] = tglBayar.year.toString();
            return item;
          }).toList();
          filterData();
        });
      } else {
        _showErrorSnackBar('Gagal memuat data dari server');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void filterData() {
    setState(() {
      String s(dynamic v) => (v ?? '').toString();
      final q = searchQuery.trim().toLowerCase();

      filteredData = rekapData.where((data) {
        // Jika ada pencarian aktif, filter berdasarkan bulan sekarang dan pencarian
        if (q.isNotEmpty) {
          final user = s(data['user']).toLowerCase();
          final tgl = s(data['tgl_bayar']).toLowerCase();
          final tagihan = s(data['tagihan']).toLowerCase();
          final rawStatus = s(data['status']).toUpperCase();
          final statusText = rawStatus == 'LS_ADMIN'
              ? 'ls admin'
              : rawStatus == 'LS'
                  ? 'lunas'
                  : rawStatus == '3'
                      ? 'transfer'
                      : 'pending';

          // Dapatkan bulan dan tahun sekarang
          final currentMonth = DateTime.now().month;
          final currentYear = DateTime.now().year.toString();

          // Filter berdasarkan bulan sekarang DAN pencarian
          bool isCurrentMonth = int.parse(data['bulan']) == currentMonth;
          bool isCurrentYear = data['tahun'] == currentYear;
          bool matchesSearch = user.contains(q) ||
              tgl.contains(q) ||
              tagihan.contains(q) ||
              statusText.contains(q);

          return isCurrentMonth && isCurrentYear && matchesSearch;
        }

        // Jika tidak ada pencarian, gunakan filter bulan/tahun
        bool monthMatch = selectedMonth.isEmpty ||
            int.parse(data['bulan']) ==
                (availableMonths.indexOf(selectedMonth) + 1);
        bool yearMatch = selectedYear.isEmpty || data['tahun'] == selectedYear;

        return monthMatch && yearMatch;
      }).toList();
      calculateTotalTagihan();
    });
  }

  void _setSearchQuery(String q) {
    searchQuery = q;
    if (_searchController.text != q) {
      _searchController.text = q;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
    filterData();
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

  Future<void> saveData() async {
    try {
      final url =
          Uri.parse('http://aplikasi.bago.web.id/api/admin/setoran_pppoe.php');
      final response = await http.post(
        url,
        body: {
          'tanggal_setor': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'jumlah_setoran': totalTagihan.toString(),
          'keterangan': 'sentul_ls_admin',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Data berhasil disimpan');
      } else {
        _showErrorSnackBar('Gagal menyimpan data');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> getSharedPrefData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cabang = prefs.getString('nama') ?? 'SENTUL';
    });
  }

  void calculateTotalTagihan() {
    double sum = 0;
    for (var rekap in filteredData) {
      sum += double.parse(rekap['tagihan']);
    }
    setState(() {
      totalTagihan = sum;
    });
  }

  Widget _buildStatsCard() {
    final numberFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[600]!, Colors.teal[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
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
                    'LS Admin - $cabang',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    searchQuery.trim().isNotEmpty
                        ? '${availableMonths[DateTime.now().month - 1]} ${DateTime.now().year} (Pencarian)'
                        : '$selectedMonth $selectedYear',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    numberFormat.format(totalTagihan),
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
                  Icons.admin_panel_settings,
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
              _buildStatItem('Total Pembayaran', '${filteredData.length}',
                  Icons.receipt_long),
              _buildStatItem('Cabang', cabang, Icons.location_on),
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

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Periode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (searchQuery.trim().isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedMonth = availableMonths[DateTime.now().month - 1];
                      selectedYear = DateTime.now().year.toString();
                      _setSearchQuery('');
                    });
                  },
                  icon: Icon(Icons.refresh, size: 16, color: Colors.teal[600]),
                  label: Text(
                    'Reset Filter',
                    style: TextStyle(
                      color: Colors.teal[600],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('Pilih Bulan'),
                      value: selectedMonth.isEmpty ? null : selectedMonth,
                      items: availableMonths.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMonth = newValue ?? '';
                          filterData();
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('Pilih Tahun'),
                      value: selectedYear.isEmpty ? null : selectedYear,
                      items: availableYears.map((String year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedYear = newValue ?? '';
                          filterData();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => _setSearchQuery(v),
        decoration: InputDecoration(
          hintText:
              'Cari nama/status/tagihan... (pencarian pada bulan ${availableMonths[DateTime.now().month - 1]})',
          prefixIcon: Icon(Icons.search, color: Colors.teal[600]),
          suffixIcon: searchQuery.trim().isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () => _setSearchQuery(''),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            'Hasil: ${filteredData.length}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (searchQuery.trim().isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal[100]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 14, color: Colors.teal[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Pencarian bulan ini',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _setSearchQuery(''),
                    child: Icon(Icons.close, size: 14, color: Colors.teal[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic rekap) {
    final numberFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final bulanIndex = int.parse(rekap['bulan']);
    final bulanName = availableMonths[bulanIndex - 1];
    final tahunValue = rekap['tahun'];
    final status = rekap['status'];
    final tanggal = rekap['tgl_bayar'] ?? '-';

    Color statusColor = status == 'LS_ADMIN'
        ? Colors.teal
        : status == 'LS'
            ? Colors.green
            : status == '3'
                ? Colors.blue
                : Colors.orange;
    String statusText = status == 'LS_ADMIN'
        ? 'LS Admin'
        : status == 'LS'
            ? 'Lunas'
            : status == '3'
                ? 'Transfer'
                : 'Pending';

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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal[100],
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: Colors.teal[600],
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rekap['user'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Periode: $bulanName $tahunValue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
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
                      numberFormat.format(double.parse(rekap['tagihan'])),
                      Icons.monetization_on,
                      Colors.green[600]!),
                  _buildDetailItem('Tanggal Bayar', tanggal,
                      Icons.calendar_today, Colors.blue[600]!),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'LS Admin - Sentul',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.teal[600]),
            onPressed: () async {
              final q = await showSearch<String?>(
                context: context,
                delegate: LsAdminSentulSearchDelegate(rekapData),
              );
              if (q != null) _setSearchQuery(q);
            },
            tooltip: 'Cari',
          ),
          IconButton(
            icon: Icon(Icons.save, color: Colors.teal[600]),
            onPressed: saveData,
            tooltip: 'Simpan Data',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.teal[600]),
            onPressed: fetchData,
            tooltip: 'Refresh Data',
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
              _buildFilterSection(),
              _buildSearchBar(),
              _buildResultsInfo(),
              SizedBox(height: 16),
              Expanded(
                child: filteredData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchQuery.trim().isNotEmpty
                                  ? Icons.search_off
                                  : Icons.data_usage_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              searchQuery.trim().isNotEmpty
                                  ? 'Tidak ada hasil untuk "${searchQuery.trim()}"'
                                  : 'Tidak ada data LS Admin untuk periode ini',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            if (searchQuery.trim().isEmpty)
                              Text(
                                '$selectedMonth $selectedYear',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            SizedBox(height: 16),
                            if (searchQuery.trim().isEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  _setSearchQuery('ls admin');
                                },
                                icon: Icon(Icons.search, size: 16),
                                label: Text('Coba Pencarian'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(filteredData[index]);
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

class LsAdminSentulSearchDelegate extends SearchDelegate<String?> {
  final List<dynamic> data;
  List<String> recent = [];

  LsAdminSentulSearchDelegate(this.data);

  @override
  String get searchFieldLabel =>
      'Cari di bulan ${DateTime.now().month}/${DateTime.now().year}...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(backgroundColor: Colors.white, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(border: InputBorder.none),
      textTheme: theme.textTheme.copyWith(
        titleLarge:
            theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  void showResults(BuildContext context) {
    final q = query.trim();
    if (q.isNotEmpty && !recent.contains(q)) recent.add(q);
    close(context, q);
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return Container();

    String s(dynamic v) => (v ?? '').toString();
    String statusText(String raw) {
      switch (raw.toUpperCase()) {
        case 'LS_ADMIN':
          return 'ls admin';
        case 'LS':
          return 'lunas';
        case '3':
          return 'transfer';
        default:
          return 'pending';
      }
    }

    final results = data.where((d) {
      // Filter berdasarkan bulan dan tahun sekarang
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year.toString();

      bool isCurrentMonth = int.parse(d['bulan']) == currentMonth;
      bool isCurrentYear = d['tahun'] == currentYear;

      // Hanya tampilkan data bulan sekarang
      if (!isCurrentMonth || !isCurrentYear) {
        return false;
      }

      final user = s(d['user']).toLowerCase();
      final tgl = s(d['tgl_bayar']).toLowerCase();
      final tagihan = s(d['tagihan']).toLowerCase();
      final status = statusText(s(d['status'])).toLowerCase();
      return user.contains(q) ||
          tgl.contains(q) ||
          tagihan.contains(q) ||
          status.contains(q);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final u = results[i];
        final name = s(u['user']);
        return ListTile(
          leading: CircleAvatar(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
          title: RichText(
            text: TextSpan(
              children: _highlightMatches(
                context,
                name.isEmpty ? '(Tanpa nama)' : name,
                query.trim(),
                baseStyle: DefaultTextStyle.of(context).style,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: RichText(
            text: TextSpan(
              children: _highlightMatches(
                context,
                s(u['tgl_bayar']),
                query.trim(),
                baseStyle: DefaultTextStyle.of(context)
                    .style
                    .copyWith(color: Colors.grey[600]),
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.north_west, size: 16, color: Colors.grey),
          onTap: () => close(context, query.trim()),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    String s(dynamic v) => (v ?? '').toString().trim();

    // Filter data untuk bulan sekarang saja
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year.toString();

    final currentMonthData = data.where((d) {
      return int.parse(d['bulan']) == currentMonth && d['tahun'] == currentYear;
    }).toList();

    final names = currentMonthData
        .map((d) => s(d['user']))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final q = query.trim().toLowerCase();

    final sug = q.isEmpty
        ? recent.reversed.toList()
        : names.where((n) => n.toLowerCase().contains(q)).take(6).toList();

    if (sug.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Mulai mengetik untuk mencari di bulan ini',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return ListView.builder(
      itemCount: sug.length,
      itemBuilder: (context, i) {
        final t = sug[i];
        final isRecent = recent.contains(t);
        return ListTile(
          leading: Icon(isRecent ? Icons.history : Icons.person_outline),
          title: RichText(
            text: TextSpan(
              children: _highlightMatches(
                context,
                t,
                query.trim(),
                baseStyle: DefaultTextStyle.of(context)
                    .style
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () =>
              close(context, query.trim().isNotEmpty ? query.trim() : t),
        );
      },
    );
  }

  List<InlineSpan> _highlightMatches(
    BuildContext context,
    String text,
    String query, {
    TextStyle? baseStyle,
  }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <InlineSpan>[];
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(
            TextSpan(text: text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + lowerQuery.length),
        style: baseStyle?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + lowerQuery.length;
    }
    return spans;
  }
}

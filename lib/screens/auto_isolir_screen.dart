import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AutoIsolirScreen extends StatefulWidget {
  const AutoIsolirScreen({Key? key}) : super(key: key);

  @override
  _AutoIsolirScreenState createState() => _AutoIsolirScreenState();
}

class _AutoIsolirScreenState extends State<AutoIsolirScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  bool isRunningCron = false;
  String filterMode = 'semua'; // semua, auto_only, belum_bayar

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Stats
  int totalAutoIsolir = 0;
  int totalBelumBayar = 0;
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/get_auto_isolir_users.php');
      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            allUsers = List<Map<String, dynamic>>.from(jsonData['data'] ?? []);
            totalUsers = allUsers.length;
            totalAutoIsolir = jsonData['total_auto_isolir'] ?? 0;
            totalBelumBayar = jsonData['total_belum_bayar'] ?? 0;
            _applyFilter();
            isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() => isLoading = false);
          _showSnackBar(jsonData['message'] ?? 'Gagal ambil data', Colors.red);
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _applyFilter() {
    String keyword = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        bool matchSearch = keyword.isEmpty ||
            (user['nama'] ?? '').toString().toLowerCase().contains(keyword) ||
            (user['alamat'] ?? '').toString().toLowerCase().contains(keyword) ||
            (user['no_hp'] ?? '').toString().toLowerCase().contains(keyword);

        bool matchFilter = true;
        if (filterMode == 'auto_only') {
          matchFilter = user['auto_isolir'] == 1;
        } else if (filterMode == 'belum_bayar') {
          matchFilter = user['sudah_bayar'] == 0;
        }

        return matchSearch && matchFilter;
      }).toList();
    });
  }

  Future<void> _toggleAutoIsolir(Map<String, dynamic> user) async {
    final idPelanggan = user['id_pelanggan'];
    final currentVal = user['auto_isolir'] ?? 0;
    final newVal = currentVal == 1 ? 0 : 1;
    final tglIsolir = user['tgl_auto_isolir'] ?? 1;

    try {
      final url = Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/set_auto_isolir.php?id_pelanggan=$idPelanggan&auto_isolir=$newVal&tgl_isolir=$tglIsolir');
      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          _showSnackBar(jsonData['message'], Colors.green);
          fetchData(); // refresh
        } else {
          _showSnackBar(jsonData['message'] ?? 'Gagal', Colors.red);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _setTanggalIsolir(Map<String, dynamic> user, int tgl) async {
    final idPelanggan = user['id_pelanggan'];
    final autoIsolir = user['auto_isolir'] ?? 0;

    try {
      final url = Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/set_auto_isolir.php?id_pelanggan=$idPelanggan&auto_isolir=$autoIsolir&tgl_isolir=$tgl');
      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          _showSnackBar('Tanggal isolir diubah ke tanggal $tgl', Colors.green);
          fetchData();
        } else {
          _showSnackBar(jsonData['message'] ?? 'Gagal', Colors.red);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _runAutoIsolirNow() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Konfirmasi'),
          ],
        ),
        content: Text(
          'Jalankan Auto Isolir sekarang?\n\nSemua pelanggan yang auto_isolir aktif dan belum bayar bulan ini akan di-isolir.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Jalankan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isRunningCron = true);

    try {
      final url = Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/auto_isolir_cron.php?force=1');
      final response = await http.get(url).timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _showResultDialog(jsonData);
        fetchData(); // refresh data
      } else {
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isRunningCron = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result['success'] == true
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: result['success'] == true ? Colors.green : Colors.red,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hasil Auto Isolir',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _resultRow('Total Dicek', '${result['total_checked'] ?? 0}'),
              _resultRow('Berhasil Isolir', '${result['total_isolir'] ?? 0}',
                  color: Colors.orange),
              _resultRow(
                  'Skip (Lunas)', '${result['total_skip_lunas'] ?? 0}',
                  color: Colors.green),
              _resultRow('Skip (Sudah Isolir)',
                  '${result['total_skip_already_isolir'] ?? 0}',
                  color: Colors.blue),
              _resultRow('Error', '${result['total_error'] ?? 0}',
                  color: Colors.red),
              SizedBox(height: 12),
              if (result['details'] != null &&
                  (result['details'] as List).isNotEmpty) ...[
                Text('Detail:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: (result['details'] as List).length,
                    itemBuilder: (context, index) {
                      final detail = result['details'][index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              _getDetailIcon(detail['status'] ?? ''),
                              size: 16,
                              color: _getDetailColor(detail['status'] ?? ''),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${detail['nama']}: ${detail['message']}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDetailIcon(String status) {
    switch (status) {
      case 'ISOLIR_SUCCESS':
        return Icons.block_rounded;
      case 'SKIP_LUNAS':
        return Icons.check_circle_rounded;
      case 'SKIP_ALREADY_ISOLIR':
        return Icons.info_rounded;
      case 'ERROR':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Color _getDetailColor(String status) {
    switch (status) {
      case 'ISOLIR_SUCCESS':
        return Colors.orange;
      case 'SKIP_LUNAS':
        return Colors.green;
      case 'SKIP_ALREADY_ISOLIR':
        return Colors.blue;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showTanggalPicker(Map<String, dynamic> user) {
    int currentTgl = user['tgl_auto_isolir'] ?? 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Pilih Tanggal Auto Isolir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'User: ${user['nama']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(28, (index) {
                final tgl = index + 1;
                final isSelected = tgl == currentTgl;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _setTanggalIsolir(user, tgl);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        '$tgl',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    try {
      final number = double.parse(amount.toString());
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
    } catch (e) {
      return amount.toString();
    }
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
          'Auto Isolir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Stats Cards
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        'Total User',
                        '$totalUsers',
                        Icons.people_rounded,
                        Colors.indigo,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildStatsCard(
                        'Auto Isolir',
                        '$totalAutoIsolir',
                        Icons.timer_rounded,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildStatsCard(
                        'Belum Bayar',
                        '$totalBelumBayar',
                        Icons.money_off_rounded,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // Run Auto Isolir Button
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isRunningCron ? null : _runAutoIsolirNow,
                  icon: isRunningCron
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: Text(
                    isRunningCron
                        ? 'Sedang Berjalan...'
                        : 'Jalankan Auto Isolir Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    disabledBackgroundColor: Colors.orange[300],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Filter Chips
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Semua', 'semua'),
                    SizedBox(width: 8),
                    _buildFilterChip('Auto Isolir', 'auto_only'),
                    SizedBox(width: 8),
                    _buildFilterChip('Belum Bayar', 'belum_bayar'),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Search Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, alamat, atau no HP...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // User List
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.indigo[600]!),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Memuat data...',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: fetchData,
                            color: Colors.indigo[600],
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(filteredUsers[index]);
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

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String mode) {
    final isSelected = filterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => filterMode = mode);
        _applyFilter();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isAutoIsolir = user['auto_isolir'] == 1;
    final sudahBayar = user['sudah_bayar'] == 1;
    final tglIsolir = user['tgl_auto_isolir'] ?? 1;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isAutoIsolir
            ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAutoIsolir
                          ? [Colors.orange, Colors.orange.shade300]
                          : [Colors.grey[400]!, Colors.grey[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (user['nama'] ?? '?')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nama'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          if (user['nama_paket'] != null &&
                              user['nama_paket'].toString().isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user['nama_paket'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.indigo[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sudahBayar
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sudahBayar ? 'Lunas' : 'Belum Bayar',
                              style: TextStyle(
                                fontSize: 10,
                                color: sudahBayar
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Toggle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isAutoIsolir,
                        onChanged: (_) => _toggleAutoIsolir(user),
                        activeColor: Colors.orange,
                        activeTrackColor: Colors.orange[200],
                      ),
                    ),
                    if (isAutoIsolir)
                      GestureDetector(
                        onTap: () => _showTanggalPicker(user),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 10, color: Colors.orange[700]),
                              SizedBox(width: 4),
                              Text(
                                'Tgl $tglIsolir',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
              Icons.timer_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada pelanggan yang tersedia',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:gojek_clone/screens/non_pppoe.dart';

class PppoeForm extends StatefulWidget {
  const PppoeForm({Key? key}) : super(key: key);
  @override
  _PppoeFormState createState() => _PppoeFormState();
}

class _PppoeFormState extends State<PppoeForm> with TickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> pppoeData = [];
  List<Map<String, dynamic>> filteredPppoeData = [];
  bool isLoading = true;
  Timer? _autoRefreshTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    try {
      var url = Uri.parse('http://aplikasi.bago.web.id/api/admin/pppoe_aktif.php');
      var response = await http.get(
        url,
        headers: {
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        var data = json.decode(response.body);
        String keyword = searchController.text;
        setState(() {
          pppoeData = List<Map<String, dynamic>>.from(data);
          // Filter hanya user aktif (online atau isolir), exclude non-aktif
          List<Map<String, dynamic>> activeOnly = pppoeData.where((pppoe) {
            return _isOnline(pppoe) ||
                pppoe['profile']?.toString().toUpperCase() == 'ISOLIR';
          }).toList();
          // Tetap filter sesuai search
          if (keyword.isNotEmpty) {
            filteredPppoeData = activeOnly.where((pppoe) {
              return pppoe['name']
                      .toString()
                      .toLowerCase()
                      .contains(keyword.toLowerCase()) ||
                  pppoe['id']
                      .toString()
                      .toLowerCase()
                      .contains(keyword.toLowerCase());
            }).toList();
          } else {
            filteredPppoeData = activeOnly;
          }
        });
      }
    } catch (_) {
      // Silent fail - jangan ganggu user
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var url = Uri.parse('http://aplikasi.bago.web.id/api/admin/pppoe_aktif.php');
      var response = await http.get(
        url,
        headers: {
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Request timeout - server terlalu lama merespons');
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          pppoeData = List<Map<String, dynamic>>.from(data);
          // Filter hanya user aktif (online atau isolir), exclude non-aktif
          filteredPppoeData = pppoeData.where((pppoe) {
            return _isOnline(pppoe) ||
                pppoe['profile']?.toString().toUpperCase() == 'ISOLIR';
          }).toList();
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Kesalahan: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void filterData(String keyword) {
    setState(() {
      // Filter hanya user aktif (online atau isolir), exclude non-aktif
      List<Map<String, dynamic>> activeOnly = pppoeData.where((pppoe) {
        return _isOnline(pppoe) ||
            pppoe['profile']?.toString().toUpperCase() == 'ISOLIR';
      }).toList();

      filteredPppoeData = activeOnly.where((pppoe) {
        bool matchesSearch = keyword.isEmpty ||
            pppoe['name']
                .toString()
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            pppoe['id']
                .toString()
                .toLowerCase()
                .contains(keyword.toLowerCase());

        return matchesSearch;
      }).toList();
    });
  }

  bool _isOnline(Map<String, dynamic> pppoe) {
    // Check status field from API first
    String status = pppoe['status']?.toString().toLowerCase() ?? '';
    if (status == 'inactive') return false;

    // Check if user is online based on uptime
    String uptime = pppoe['uptime']?.toString() ?? '';
    return uptime.isNotEmpty &&
        uptime != '0' &&
        uptime != '-' &&
        uptime.toUpperCase() != 'N/A';
  }

  String _formatUptime(String uptime) {
    if (uptime.isEmpty ||
        uptime == '0' ||
        uptime == '-' ||
        uptime.toUpperCase() == 'N/A') {
      return 'Offline';
    }

    try {
      // Parse uptime format (assuming it's in seconds or duration format)
      if (uptime.contains(':')) {
        return uptime; // Already formatted
      } else {
        int seconds = int.parse(uptime);
        int hours = seconds ~/ 3600;
        int minutes = (seconds % 3600) ~/ 60;
        int secs = seconds % 60;

        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else if (minutes > 0) {
          return '${minutes}m ${secs}s';
        } else {
          return '${secs}s';
        }
      }
    } catch (e) {
      return uptime;
    }
  }

  Color _getStatusColor(Map<String, dynamic> pppoe) {
    // Check if isolated first
    if (pppoe['profile']?.toString().toUpperCase() == 'ISOLIR') {
      return Colors.orange;
    }
    return _isOnline(pppoe) ? Colors.green : Colors.red;
  }

  String _getStatusText(Map<String, dynamic> pppoe) {
    // Check if isolated first
    if (pppoe['profile']?.toString().toUpperCase() == 'ISOLIR') {
      return 'Isolir';
    }
    return _isOnline(pppoe) ? 'Online' : 'Offline';
  }

  void _showUserDetail(Map<String, dynamic> pppoeData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: PppoeDetailSheet(
            pppoeData: pppoeData,
            onRefresh: fetchData,
          ),
        ),
      ),
    );
  }

  int get onlineCount => pppoeData
      .where((pppoe) =>
          _isOnline(pppoe) &&
          pppoe['profile']?.toString().toUpperCase() != 'ISOLIR' &&
          pppoe['status']?.toString() != 'inactive')
      .length;

  int get isolirCount => pppoeData
      .where((pppoe) => pppoe['profile']?.toString().toUpperCase() == 'ISOLIR')
      .length;

  int get nonAktifCount => pppoeData
      .where((pppoe) =>
          !_isOnline(pppoe) &&
          pppoe['profile']?.toString().toUpperCase() != 'ISOLIR')
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'PPPoE Active Users',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: fetchData,
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
              // Stats Cards - 3 cards
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSmallStatsCard(
                        'Online',
                        '$onlineCount',
                        Icons.wifi_rounded,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallStatsCard(
                        'Isolir',
                        '$isolirCount',
                        Icons.block_rounded,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NonAktifPppoe(),
                            ),
                          );
                          fetchData();
                        },
                        child: _buildSmallStatsCard(
                          'Non-Aktif',
                          '$nonAktifCount',
                          Icons.wifi_off_rounded,
                          Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                    controller: searchController,
                    onChanged: filterData,
                    decoration: InputDecoration(
                      hintText: 'Cari nama pengguna atau ID...',
                      prefixIcon:
                          Icon(Icons.search_rounded, color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Data List
              Expanded(
                child: Stack(
                  children: [
                    filteredPppoeData.isEmpty && !isLoading
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: fetchData,
                            color: Colors.indigo[600],
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredPppoeData.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(
                                    filteredPppoeData[index], index);
                              },
                            ),
                          ),
                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Card(
                            margin: EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.indigo[600]!),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memuat data...',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStatsCard(
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
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
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

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> pppoeData, int index) {
    bool isOnline = _isOnline(pppoeData);

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetail(pppoeData),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Indicator & Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(pppoeData),
                        _getStatusColor(pppoeData).withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          pppoeData['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pppoeData['name'] ?? '',
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
                            Icons.fingerprint_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ID: ${pppoeData['id'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOnline
                                ? Icons.access_time_rounded
                                : Icons.schedule_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatUptime(
                                pppoeData['uptime']?.toString() ?? ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(pppoeData).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(pppoeData),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(pppoeData),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey[400],
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
              Icons.wifi_off_rounded,
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
            'Belum ada pengguna PPPoE yang tersedia',
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

// PPPoE Detail Bottom Sheet
class PppoeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> pppoeData;
  final VoidCallback? onRefresh;

  const PppoeDetailSheet({Key? key, required this.pppoeData, this.onRefresh})
      : super(key: key);

  bool _isOnline() {
    // Check status field from API first
    String status = pppoeData['status']?.toString().toLowerCase() ?? '';
    if (status == 'inactive') return false;

    String uptime = pppoeData['uptime']?.toString() ?? '';
    return uptime.isNotEmpty &&
        uptime != '0' &&
        uptime != '-' &&
        uptime.toUpperCase() != 'N/A';
  }

  Color _getStatusColor() {
    // Check if isolated first
    if (pppoeData['profile']?.toString().toUpperCase() == 'ISOLIR') {
      return Colors.orange;
    }
    return _isOnline() ? Colors.green : Colors.red;
  }

  String _getStatusText() {
    // Check if isolated first
    if (pppoeData['profile']?.toString().toUpperCase() == 'ISOLIR') {
      return 'Isolir';
    }
    return _isOnline() ? 'Online' : 'Offline';
  }

  String _formatUptime(String uptime) {
    if (uptime.isEmpty ||
        uptime == '0' ||
        uptime == '-' ||
        uptime.toUpperCase() == 'N/A') {
      return 'Tidak aktif';
    }

    try {
      if (uptime.contains(':')) {
        return uptime;
      } else {
        int seconds = int.parse(uptime);
        int days = seconds ~/ 86400;
        int hours = (seconds % 86400) ~/ 3600;
        int minutes = (seconds % 3600) ~/ 60;
        int secs = seconds % 60;

        String result = '';
        if (days > 0) result += '${days}d ';
        if (hours > 0) result += '${hours}h ';
        if (minutes > 0) result += '${minutes}m ';
        if (secs > 0 && days == 0) result += '${secs}s';

        return result.trim();
      }
    } catch (e) {
      return uptime;
    }
  }

  void _showIsolirConfirmation(BuildContext context) {
    bool isIsolated =
        pppoeData['profile']?.toString().toUpperCase() == 'ISOLIR';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isIsolated ? Icons.check_circle_outline : Icons.warning_rounded,
                color: isIsolated ? Colors.green : Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(isIsolated ? 'Konfirmasi Aktifkan' : 'Konfirmasi Isolir'),
            ],
          ),
          content: Text(
            isIsolated
                ? 'Apakah Anda yakin ingin mengaktifkan kembali user "${pppoeData['name']}"?\n\nUser akan dikembalikan ke profile semula.'
                : 'Apakah Anda yakin ingin mengisolir user "${pppoeData['name']}"?\n\nUser akan dipindahkan ke profile ISOLIR dan koneksi aktif akan diputus.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog with dialog's own context
                _toggleIsolir(context);       // Pass outer (bottom sheet) context
              },
              child: Text(isIsolated ? 'Ya, Aktifkan' : 'Ya, Isolir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isIsolated ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _isolirUser(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: EdgeInsets.all(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengisolir user...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      String username = pppoeData['name']?.toString() ?? '';
      var url = Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/isolir_user.php?username=$username');
      var response = await http.get(url);

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        var result = json.decode(response.body);

        if (result['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                      child:
                          Text(result['message'] ?? 'User berhasil diisolir')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Close detail sheet and refresh data
          Navigator.pop(context);
        } else {
          _showErrorDialog(
              context, result['message'] ?? 'Gagal mengisolir user');
        }
      } else {
        _showErrorDialog(
            context, 'Gagal menghubungi server: ${response.statusCode}');
      }
    } catch (error) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'Kesalahan: $error');
    }
  }

  Future<void> _toggleIsolir(BuildContext context) async {
    bool isIsolated =
        pppoeData['profile']?.toString().toUpperCase() == 'ISOLIR';

    // Save navigator & scaffoldMessenger before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Card(
          margin: EdgeInsets.all(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                    isIsolated ? 'Mengaktifkan user...' : 'Mengisolir user...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      String username = pppoeData['name']?.toString() ?? '';
      var url = Uri.parse(
          'http://aplikasi.bago.web.id/api/admin/toggle_isolir.php?username=$username');
      var response = await http.get(url);

      // Close loading dialog
      if (navigator.canPop()) navigator.pop();

      if (response.statusCode == 200) {
        var result = json.decode(response.body);

        if (result['success'] == true) {
          // Show success message
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text(result['message'] ?? 'Berhasil')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Close detail sheet and refresh data
          if (navigator.canPop()) navigator.pop();

          // Refresh data list
          if (onRefresh != null) {
            onRefresh!();
          }
        } else {
          // Use navigator.context which remains valid
          if (navigator.context.mounted) {
            _showErrorDialog(
                navigator.context, result['message'] ?? 'Gagal mengubah status user');
          }
        }
      } else {
        if (navigator.context.mounted) {
          _showErrorDialog(
              navigator.context, 'Gagal menghubungi server: ${response.statusCode}');
        }
      }
    } catch (error) {
      // Close loading dialog
      if (navigator.canPop()) navigator.pop();
      if (navigator.context.mounted) {
        _showErrorDialog(navigator.context, 'Kesalahan: $error');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(),
                        _getStatusColor().withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          pppoeData['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _isOnline() ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pppoeData['name'] ?? '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard(
                  'Informasi Koneksi',
                  [
                    _buildDetailItem(
                        'ID Pengguna',
                        pppoeData['id']?.toString() ?? '',
                        Icons.fingerprint_rounded),
                    _buildDetailItem(
                        'Nama',
                        pppoeData['name']?.toString() ?? '',
                        Icons.person_rounded),
                    _buildDetailItem('Status', _getStatusText(),
                        Icons.signal_wifi_4_bar_rounded),
                    _buildDetailItem(
                        'Uptime',
                        _formatUptime(pppoeData['uptime']?.toString() ?? ''),
                        Icons.access_time_rounded),
                  ],
                ),
                SizedBox(height: 16),
                if (pppoeData.containsKey('address') ||
                    pppoeData.containsKey('profile') ||
                    pppoeData.containsKey('service'))
                  _buildDetailCard(
                    'Informasi Teknis',
                    [
                      if (pppoeData.containsKey('address'))
                        _buildDetailItem(
                            'Alamat IP',
                            pppoeData['address']?.toString() ?? '',
                            Icons.language_rounded),
                      if (pppoeData.containsKey('profile'))
                        _buildDetailItem(
                            'Profile',
                            pppoeData['profile']?.toString() ?? '',
                            Icons.settings_rounded),
                      if (pppoeData.containsKey('service'))
                        _buildDetailItem(
                            'Service',
                            pppoeData['service']?.toString() ?? '',
                            Icons.router_rounded),
                    ],
                  ),
                SizedBox(height: 16),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Builder(
                      builder: (context) {
                        bool isIsolated =
                            pppoeData['profile']?.toString().toUpperCase() ==
                                'ISOLIR';
                        return ElevatedButton(
                          onPressed: () => _showIsolirConfirmation(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isIsolated ? Colors.green : Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isIsolated ? 'Aktifkan' : 'Isolir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

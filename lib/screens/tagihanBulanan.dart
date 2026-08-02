import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gojek_clone/screens/UserSearch.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class TagihanBulanan extends StatefulWidget {
  @override
  _TagihanBulananState createState() => _TagihanBulananState();
}

class _TagihanBulananState extends State<TagihanBulanan>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  String selectedCabang = 'Semua';
  List<String> cabangList = ['Semua'];
  bool isLoading = true;

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

    final url = Uri.parse('http://aplikasi.bago.web.id/api/admin/t_bulanan.php');

    try {
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          data = List<Map<String, dynamic>>.from(jsonData);
          filteredData = data;
          isLoading = false;

          // Mengumpulkan cabang unik
          Set<String> uniqueCabang = {'Semua'};
          for (var item in data) {
            if (item['cabang'] != null &&
                item['cabang'].toString().isNotEmpty) {
              uniqueCabang.add(item['cabang'].toString());
            }
          }
          cabangList = uniqueCabang.toList();
        });
        _animationController.forward();
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (error) {
      if (!mounted) return;
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

  void filterData(String query) {
    if (!mounted) return;

    setState(() {
      filteredData = data.where((item) {
        bool matchesQuery = query.isEmpty ||
            item['user']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            item['nohp']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            item['tagihan']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            item['cabang']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        bool matchesCabang = selectedCabang == 'Semua' ||
            item['cabang'].toString() == selectedCabang;

        return matchesQuery && matchesCabang;
      }).toList();
    });
  }

  String _formatCurrency(String amount) {
    try {
      final number = double.parse(amount);
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
    } catch (e) {
      return amount;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getBranchColor(String cabang) {
    switch (cabang.toLowerCase()) {
      case 'bago':
        return Colors.blue;
      case 'sentul':
        return Colors.purple;
      case 'plaosan':
        return Colors.green;
      case 'mandati':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showUserDetail(Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailSheet(
        userData: userData,
        onEdit: () => _navigateToEditPage(userData),
        onDelete: () => _deleteUser(userData),
        onWhatsApp: () => _sendWhatsApp(userData),
        onSearch: () => _searchUser(userData),
      ),
    );
  }

  void _navigateToEditPage(Map<String, dynamic> rowData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(
          data: rowData,
          tagihanBulanan: widget,
          onDataUpdated: fetchData,
        ),
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content:
            Text('Apakah Anda yakin ingin menghapus data ${userData['user']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // Close bottom sheet
              await _performDelete(userData['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String id) async {
    try {
      final response = await http.post(
        Uri.parse('http://aplikasi.bago.web.id/api/admin/d_bulanan.php'),
        body: {'id': id},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        fetchData();
      } else {
        _showErrorSnackBar('Gagal menghapus data');
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Error: $error');
    }
  }

  void _sendWhatsApp(Map<String, dynamic> userData) {
    final message =
        "Halo ${userData['user']} tagihan anda sebesar ${_formatCurrency(userData['tagihan'])} Mohon segera di bayar, Terimakasih. Info Tanggal sekarang : ${DateFormat('dd MMM yyyy').format(DateTime.now())}";
    final uri = Uri.parse("https://wa.me/${userData['nohp']}?text=$message");
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _searchUser(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          cari: userData['user'],
          tagihanBulanan: widget,
        ),
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
          'Tagihan Bulanan',
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
              // Stats Card
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[600]!, Colors.indigo[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pengguna',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${filteredData.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
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
              ),

              // Filter Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Branch Filter
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCabang,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down_rounded),
                          items: cabangList.map((String cabang) {
                            return DropdownMenuItem<String>(
                              value: cabang,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getBranchColor(cabang),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(cabang),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCabang = newValue!;
                              filterData(_searchController.text);
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Search Bar
                    Container(
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
                        onChanged: filterData,
                        decoration: InputDecoration(
                          hintText: 'Cari nama, nomor HP, atau tagihan...',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Data List
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
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredData.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: fetchData,
                            color: Colors.indigo[600],
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(
                                    filteredData[index], index);
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

  Widget _buildUserCard(Map<String, dynamic> userData, int index) {
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
          onTap: () => _showUserDetail(userData),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getBranchColor(userData['cabang'] ?? ''),
                        _getBranchColor(userData['cabang'] ?? '')
                            .withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      userData['user'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                        userData['user'] ?? '',
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
                            Icons.phone_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            userData['nohp'] ?? '',
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
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getBranchColor(userData['cabang'] ?? '')
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              userData['cabang'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    _getBranchColor(userData['cabang'] ?? ''),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tagihan Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(userData['tagihan'] ?? '0'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tagihan',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
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
              Icons.people_outline_rounded,
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
            'Belum ada data pengguna yang tersedia',
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

// User Detail Bottom Sheet
class UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWhatsApp;
  final VoidCallback onSearch;

  const UserDetailSheet({
    Key? key,
    required this.userData,
    required this.onEdit,
    required this.onDelete,
    required this.onWhatsApp,
    required this.onSearch,
  }) : super(key: key);

  String _formatCurrency(String amount) {
    try {
      final number = double.parse(amount);
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
    } catch (e) {
      return amount;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getBranchColor(String cabang) {
    switch (cabang.toLowerCase()) {
      case 'bago':
        return Colors.blue;
      case 'sentul':
        return Colors.purple;
      case 'plaosan':
        return Colors.green;
      case 'mandati':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

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
                            _getBranchColor(userData['cabang'] ?? ''),
                            _getBranchColor(userData['cabang'] ?? '')
                                .withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          userData['user']
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
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['user'] ?? '',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getBranchColor(userData['cabang'] ?? '')
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userData['cabang'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    _getBranchColor(userData['cabang'] ?? ''),
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailCard(
                        'Informasi Kontak',
                        [
                          _buildDetailItem('Nomor HP', userData['nohp'] ?? '',
                              Icons.phone_rounded),
                          _buildDetailItem('ID Pengguna', userData['id'] ?? '',
                              Icons.fingerprint_rounded),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildDetailCard(
                        'Informasi Tagihan',
                        [
                          _buildDetailItem(
                              'Jumlah Tagihan',
                              _formatCurrency(userData['tagihan'] ?? '0'),
                              Icons.payment_rounded),
                          _buildDetailItem('Status', userData['status'] ?? '',
                              Icons.info_rounded),
                          _buildDetailItem(
                              'Tanggal Masuk',
                              _formatDate(userData['tgl_masuk'] ?? ''),
                              Icons.calendar_today_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onWhatsApp,
                            icon: Icon(Icons.message_rounded),
                            label: Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onSearch,
                            icon: Icon(Icons.search_rounded),
                            label: Text('Cari'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: Icon(Icons.edit_rounded),
                            label: Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                              side: BorderSide(color: Colors.indigo),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: Icon(Icons.delete_rounded),
                            label: Text('Hapus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

// Enhanced Edit Page
class EditPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final TagihanBulanan tagihanBulanan;
  final VoidCallback onDataUpdated;

  EditPage({
    required this.data,
    required this.tagihanBulanan,
    required this.onDataUpdated,
  });

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _tagihanController;
  late TextEditingController _tglMasukController;
  late TextEditingController _statusController;
  late TextEditingController _cabangController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.data['id']);
    _nameController = TextEditingController(text: widget.data['user']);
    _phoneController = TextEditingController(text: widget.data['nohp']);
    _tagihanController = TextEditingController(text: widget.data['tagihan']);
    _tglMasukController = TextEditingController(text: widget.data['tgl_masuk']);
    _statusController = TextEditingController(text: widget.data['status']);
    _cabangController = TextEditingController(text: widget.data['cabang']);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _tagihanController.dispose();
    _tglMasukController.dispose();
    _statusController.dispose();
    _cabangController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    Map<String, String> data = {
      'id': widget.data['id'],
      'user': _nameController.text,
      'nohp': _phoneController.text,
      'tagihan': _tagihanController.text,
      'tgl_masuk': _tglMasukController.text,
      'status': _statusController.text,
      'cabang': _cabangController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://aplikasi.bago.web.id/api/admin/e_bulanan.php'),
        body: data,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onDataUpdated();
        Navigator.pop(context);
      } else {
        _showErrorSnackBar('Gagal memperbarui data');
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Edit Pengguna',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard([
              _buildTextField(_idController, 'ID', enabled: false),
              _buildTextField(_nameController, 'Nama Pengguna'),
              _buildTextField(_phoneController, 'Nomor HP'),
            ]),
            SizedBox(height: 16),
            _buildInputCard([
              _buildTextField(_tagihanController, 'Tagihan'),
              _buildTextField(_tglMasukController, 'Tanggal Masuk'),
              _buildTextField(_statusController, 'Status'),
              _buildTextField(_cabangController, 'Cabang'),
            ]),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: !enabled,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}

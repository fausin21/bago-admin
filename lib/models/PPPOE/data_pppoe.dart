import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gojek_clone/network/network.dart';

class UserTable extends StatefulWidget {
  @override
  _UserTableState createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> with TickerProviderStateMixin {
  late Future<List<dynamic>> _userListFuture;
  List<dynamic> _userList = [];
  String currentQuery = '';
  int totalUsers = 0;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    fetchTotalUsers();
    _userListFuture = fetchUserList(currentQuery);
    _animationController.forward();

    Future.delayed(Duration(milliseconds: 800), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchUserList(String query) async {
    final response = await http.get(
        Uri.parse('${Network.Url}/api/admin/admin_baru/user_pppoe.php'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      // Reverse agar data terbaru muncul di atas
      return data.reversed.toList();
    } else {
      throw Exception('Failed to load user list');
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _userListFuture = fetchUserList(currentQuery);
    });
    await fetchTotalUsers();
  }

  Future<void> fetchTotalUsers() async {
    final response = await http.get(Uri.parse(
        '${Network.Url}/api/admin/admin_baru/ppp/hitung.php?count=true'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        totalUsers = jsonData['total'] as int;
      });
    } else {
      throw Exception('Failed to load total user count');
    }
  }

  void filterUsers(String query) {
    currentQuery = query;
    setState(() {
      // Filter dilakukan di sisi UI menggunakan _getFilteredUsers
    });
  }

  // Helper untuk memfilter data pengguna berdasarkan currentQuery
  List<dynamic> _getFilteredUsers(List<dynamic> users) {
    final q = currentQuery.trim().toLowerCase();
    if (q.isEmpty) return users;

    bool contains(dynamic v) {
      final s = (v ?? '').toString().toLowerCase();
      return s.contains(q);
    }

    return users.where((u) {
      return contains(u['nama']) ||
          contains(u['alamat']) ||
          contains(u['no_hp']) ||
          contains(u['email']) ||
          contains(u['paket']) ||
          contains(u['id_pelanggan']);
    }).toList();
  }

  String _formatCurrency(String amount) {
    try {
      int value = int.parse(amount);
      return value.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } catch (e) {
      return amount;
    }
  }

  // Format rupiah
  String _formatRupiah(double value) {
    if (value == 0) return 'Rp 0';
    String result = value.toStringAsFixed(0);
    String formatted = '';
    int count = 0;
    for (int i = result.length - 1; i >= 0; i--) {
      count++;
      formatted = result[i] + formatted;
      if (count % 3 == 0 && i != 0) {
        formatted = '.' + formatted;
      }
    }
    return 'Rp $formatted';
  }

  Future<List<dynamic>> fetchPackages() async {
    final response = await http
        .get(Uri.parse('http://aplikasi.bago.web.id/api/admin/paket.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load packages');
    }
  }

  Future<List<dynamic>> fetchTechnicians() async {
    final response = await http
        .get(Uri.parse('http://aplikasi.bago.web.id/api/admin/teknisi.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load technicians');
    }
  }

  Future<List<dynamic>> fetchMikrotik() async {
    final response = await http
        .get(Uri.parse('http://aplikasi.bago.web.id/api/admin/mikrotik.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load mikrotik');
    }
  }

  Future<List<String>> fetchProfiles(String mikrotikId) async {
    final response = await http.get(Uri.parse(
        'http://aplikasi.bago.web.id/api/admin/get_mikrotik_profiles.php?id_mikrotik=$mikrotikId'));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success'] == true && data['profiles'] is List) {
        return List<String>.from(data['profiles']);
      }
    }
    return [];
  }

  void showUserDetailBottomSheet(dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                margin: EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with avatar and info
                      Container(
                        padding: EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'user_${user['id_pelanggan']}',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    user['nama'].toString().isNotEmpty
                                        ? user['nama'][0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['nama'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: ((user['status'] ?? 'Aktif')
                                                  .toString()
                                                  .toLowerCase() ==
                                              'aktif')
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (user['status'] ?? 'Aktif').toString(),
                                      style: TextStyle(
                                        color: ((user['status'] ?? 'Aktif')
                                                    .toString()
                                                    .toLowerCase() ==
                                                'aktif')
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.close_rounded, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Detail Cards
                      Text(
                        'Informasi Detail',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20),

                      _buildModernDetailCard(
                        icon: Icons.person_outline,
                        title: 'ID Pelanggan',
                        content: user['id_pelanggan'] ?? 'N/A',
                        color: Colors.indigo,
                        iconBg: Colors.indigo[50]!,
                      ),
                      SizedBox(height: 15),

                      _buildModernDetailCard(
                        icon: Icons.account_circle_outlined,
                        title: 'Username PPPoE',
                        content: user['username'] ?? '-',
                        color: Colors.amber,
                        iconBg: Colors.amber[50]!,
                      ),
                      SizedBox(height: 15),

                      _buildModernDetailCard(
                        icon: Icons.wifi_rounded,
                        title: 'Paket Internet',
                        content: user['paket'] ?? 'Tidak diketahui',
                        color: Colors.purple,
                        iconBg: Colors.purple[50]!,
                      ),
                      SizedBox(height: 15),

                      _buildModernDetailCard(
                        icon: Icons.payments_outlined,
                        title: 'Tagihan Bulanan',
                        content: 'Rp ${_formatCurrency(user['tarif'] ?? '0')}',
                        color: Colors.green,
                        iconBg: Colors.green[50]!,
                      ),
                      SizedBox(height: 15),

                      _buildModernDetailCard(
                        icon: Icons.location_city_outlined,
                        title: 'Alamat',
                        content: user['alamat'],
                        color: Colors.orange,
                        iconBg: Colors.orange[50]!,
                      ),
                      SizedBox(height: 15),

                      _buildModernDetailCard(
                        icon: Icons.phone_outlined,
                        title: 'Nomor Telepon',
                        content: user['no_hp'],
                        color: Colors.blue,
                        iconBg: Colors.blue[50]!,
                      ),
                      SizedBox(height: 15),

                      _buildModernDetailCard(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        content: user['email'],
                        color: Colors.teal,
                        iconBg: Colors.teal[50]!,
                      ),

                      SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showEditDialog(user: user);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              height: 55,
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  _showDeleteConfirmDialog(user);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[600],
                                  side: BorderSide(
                                      color: Colors.red[300]!, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color iconBg,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red[600]),
            ),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus pengguna "${user['nama']}"?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await deleteUser(user['id_pelanggan']);
                _showSnackBar('Pengguna berhasil dihapus', Colors.green);
              } catch (e) {
                _showSnackBar('Gagal menghapus pengguna', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void showEditDialog({dynamic user}) {
    final bool isEdit = user != null;
    TextEditingController namaController =
        TextEditingController(text: isEdit ? user['nama'] : '');
    TextEditingController alamatController =
        TextEditingController(text: isEdit ? user['alamat'] : '');
    TextEditingController noHpController =
        TextEditingController(text: isEdit ? user['no_hp'] : '');

    String? selectedPaket;
    String? selectedTeknisi;
    String? selectedMikrotik;
    String? selectedProfile;
    double selectedHarga = 0;
    List<String> profileList = [];
    bool isLoadingProfile = false;
    List<dynamic> paketListData = [];
    List<dynamic> mikrotikListData = [];
    List<dynamic> teknisiListData = [];

    // Pre-fetch futures sekali saja untuk mencegah re-fetch saat rebuild
    final Future<List<dynamic>> paketFuture = fetchPackages();
    final Future<List<dynamic>> mikrotikFuture = fetchMikrotik();
    final Future<List<dynamic>> teknisiFuture = fetchTechnicians();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 16,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 600
                      ? 500
                      : double.infinity,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Theme.of(context).primaryColor.withOpacity(0.02),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.person_add_rounded,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          isEdit ? 'Edit Pengguna' : 'Tambah Pengguna Baru',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          isEdit
                              ? 'Perbarui informasi pengguna'
                              : 'Masukkan detail pengguna baru',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 32),
                        _buildTextField(
                          controller: namaController,
                          label: 'Nama Lengkap',
                          icon: Icons.person_rounded,
                          hint: 'Masukkan nama lengkap',
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: alamatController,
                          label: 'Alamat',
                          icon: Icons.location_on_rounded,
                          hint: 'Masukkan alamat lengkap',
                          maxLines: 2,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: noHpController,
                          label: 'Nomor Telepon',
                          icon: Icons.phone_rounded,
                          hint: 'Masukkan nomor telepon',
                          keyboardType: TextInputType.phone,
                        ),
                        if (!isEdit) ...[
                          SizedBox(height: 20),
                          // Paket dengan harga (dengan cache)
                          FutureBuilder<List<dynamic>>(
                            future: paketFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text('Gagal memuat paket');
                              }

                              // Cache data paket
                              if (paketListData.isEmpty) {
                                paketListData = snapshot.data!;
                              }

                              return Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: Offset(0, 4)),
                                      ],
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: selectedPaket,
                                      decoration: InputDecoration(
                                        labelText: 'Paket Internet',
                                        hintText: 'Pilih paket internet',
                                        prefixIcon: Container(
                                          margin: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.wifi_rounded,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      items: paketListData
                                          .map<DropdownMenuItem<String>>((p) {
                                        double tarif = double.tryParse(
                                                p['tarif'].toString()) ??
                                            0;
                                        return DropdownMenuItem<String>(
                                          value: p['id_paket'].toString(),
                                          child: Text(
                                              '${p['paket']} - ${_formatRupiah(tarif)}'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          var paket = paketListData.firstWhere(
                                              (p) =>
                                                  p['id_paket'].toString() ==
                                                  value,
                                              orElse: () => {});
                                          setDialogState(() {
                                            selectedPaket = value;
                                            if (paket.isNotEmpty) {
                                              selectedHarga = double.tryParse(
                                                      paket['tarif']
                                                          .toString()) ??
                                                  0;
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  // Box Harga
                                  if (selectedHarga > 0)
                                    Container(
                                      margin: EdgeInsets.only(top: 12),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Color(0xFF22C55E)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.payments_outlined,
                                              color: Color(0xFF22C55E)),
                                          SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Harga Paket:',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600])),
                                              Text(_formatRupiah(selectedHarga),
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF22C55E))),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          // Mikrotik
                          FutureBuilder<List<dynamic>>(
                            future: mikrotikFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Center(
                                      child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty)
                                return Text('Gagal memuat mikrotik');

                              // Simpan data mikrotik
                              if (mikrotikListData.isEmpty) {
                                mikrotikListData = snapshot.data!;
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4))
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedMikrotik,
                                  decoration: InputDecoration(
                                    labelText: 'Mikrotik',
                                    hintText: 'Pilih mikrotik',
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.router_rounded,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: mikrotikListData
                                      .map<DropdownMenuItem<String>>((m) {
                                    return DropdownMenuItem<String>(
                                      value: m['id'].toString(),
                                      child: Text('${m['nama']} (${m['ip']})'),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (context) {
                                    return mikrotikListData.map<Widget>((m) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child:
                                            Text('${m['nama']} (${m['ip']})'),
                                      );
                                    }).toList();
                                  },
                                  onChanged: (value) async {
                                    selectedMikrotik = value;
                                    if (value != null) {
                                      setDialogState(() {
                                        isLoadingProfile = true;
                                        profileList = [];
                                        selectedProfile = null;
                                      });
                                      var profiles = await fetchProfiles(value);
                                      setDialogState(() {
                                        profileList = profiles;
                                        isLoadingProfile = false;
                                      });
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          // Profile Mikrotik
                          if (selectedMikrotik != null) ...[
                            SizedBox(height: 20),
                            if (isLoadingProfile)
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                    SizedBox(width: 8),
                                    Text('Memuat profile...'),
                                  ],
                                ),
                              )
                            else if (profileList.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4))
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Profile Mikrotik',
                                    hintText: 'Pilih profile',
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.settings_ethernet,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: profileList
                                      .map<DropdownMenuItem<String>>((p) {
                                    return DropdownMenuItem<String>(
                                        value: p, child: Text(p));
                                  }).toList(),
                                  onChanged: (value) => selectedProfile = value,
                                ),
                              ),
                          ],
                          SizedBox(height: 20),
                          // Teknisi dengan cache
                          FutureBuilder<List<dynamic>>(
                            future: teknisiFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Center(
                                      child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty)
                                return Text('Gagal memuat teknisi');

                              if (teknisiListData.isEmpty) {
                                teknisiListData = snapshot.data!;
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4))
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedTeknisi,
                                  decoration: InputDecoration(
                                    labelText: 'Teknisi',
                                    hintText: 'Pilih teknisi',
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.engineering_rounded,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: teknisiListData
                                      .map<DropdownMenuItem<String>>((t) {
                                    return DropdownMenuItem<String>(
                                      value: t['id'].toString(),
                                      child: Text(t['nama'].toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedTeknisi = value;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                        SizedBox(height: 40),
                        _buildDialogActions(
                          isEdit: isEdit,
                          user: user,
                          namaController: namaController,
                          alamatController: alamatController,
                          noHpController: noHpController,
                          selectedPaket: selectedPaket,
                          selectedTeknisi: selectedTeknisi,
                          selectedMikrotik: selectedMikrotik,
                          selectedProfile: selectedProfile,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required Future<List<dynamic>> future,
    required String label,
    required IconData icon,
    required String hint,
    required void Function(String?) onChanged,
    required DropdownMenuItem<String> Function(dynamic) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('Error loading data',
                    style: TextStyle(color: Colors.red)),
              ),
            );
          } else {
            final items = snapshot.data!;
            return DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                labelStyle: TextStyle(color: Colors.grey[700]),
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              items: items.map<DropdownMenuItem<String>>(itemBuilder).toList(),
              onChanged: onChanged,
            );
          }
        },
      ),
    );
  }

  Widget _buildDialogActions({
    required bool isEdit,
    dynamic user,
    required TextEditingController namaController,
    required TextEditingController alamatController,
    required TextEditingController noHpController,
    String? selectedPaket,
    String? selectedTeknisi,
    String? selectedMikrotik,
    String? selectedProfile,
  }) {
    if (isEdit) {
      return Column(
        children: [
          // Top row: Cancel and Delete buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, size: 18),
                  label: Text('Batal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await deleteUser(user['id_pelanggan']);
                      Navigator.pop(context);
                      _showSnackBar('Pengguna berhasil dihapus', Colors.green);
                    } catch (e) {
                      _showSnackBar('Gagal menghapus pengguna', Colors.red);
                    }
                  },
                  icon: Icon(Icons.delete_rounded, size: 18),
                  label: Text('Hapus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Bottom row: Save button (full width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await editUser(
                    user['id_pelanggan'],
                    namaController.text,
                    alamatController.text,
                    noHpController.text,
                    user['email'],
                    user['password'],
                    user['level'],
                    user['id_paket'],
                    user['id_teknisi'],
                  );
                  Navigator.pop(context);
                  _showSnackBar('Pengguna berhasil diperbarui', Colors.green);
                } catch (e) {
                  _showSnackBar('Gagal memperbarui pengguna', Colors.red);
                }
              },
              icon: Icon(Icons.save_rounded, size: 18),
              label: Text('Simpan Perubahan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, size: 18),
              label: Text('Batal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Debug log
                debugPrint('=== SUBMIT DEBUG ===');
                debugPrint('Nama: ${namaController.text.trim()}');
                debugPrint('Alamat: ${alamatController.text.trim()}');
                debugPrint('NoHP: ${noHpController.text.trim()}');
                debugPrint('Paket: $selectedPaket');
                debugPrint('Teknisi: $selectedTeknisi');
                debugPrint('Mikrotik: $selectedMikrotik');
                debugPrint('Profile: $selectedProfile');

                // Validasi input
                if (namaController.text.trim().isEmpty) {
                  _showSnackBar('Nama tidak boleh kosong', Colors.red);
                  return;
                }
                if (alamatController.text.trim().isEmpty) {
                  _showSnackBar('Alamat tidak boleh kosong', Colors.red);
                  return;
                }
                if (selectedPaket == null) {
                  _showSnackBar('Pilih paket terlebih dahulu', Colors.orange);
                  return;
                }
                if (selectedTeknisi == null) {
                  _showSnackBar('Pilih teknisi terlebih dahulu', Colors.orange);
                  return;
                }
                if (selectedMikrotik == null) {
                  _showSnackBar(
                      'Pilih mikrotik terlebih dahulu', Colors.orange);
                  return;
                }

                try {
                  await addUser(
                    namaController.text.trim(),
                    alamatController.text.trim(),
                    noHpController.text.trim(),
                    selectedPaket,
                    selectedTeknisi,
                    id_mikrotik: selectedMikrotik,
                    profile: selectedProfile,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('Error tambah user: $e');
                  _showSnackBar('Gagal: $e', Colors.red);
                }
              },
              icon: Icon(Icons.add_rounded, size: 18),
              label: Text('Tambah Pengguna'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> deleteUser(String id_pelanggan) async {
    final response = await http.post(
      Uri.parse(
          '${Network.Url}/api/admin/admin_baru/ppp/delete_user.php'),
      body: {
        'id_pelanggan': id_pelanggan,
      },
    );
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['message'] == 'User deleted successfully') {
        refreshData();
        fetchTotalUsers();
      } else {
        throw Exception('Failed to delete user');
      }
    } else {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> editUser(
      String id_pelanggan,
      String nama,
      String alamat,
      String no_hp,
      String email,
      String password,
      String level,
      String id_paket,
      String id_teknisi) async {
    final response = await http.post(
      Uri.parse('${Network.Url}/api/admin/admin_baru/ppp/edit_user.php'),
      body: {
        'id_pelanggan': id_pelanggan,
        'nama': nama,
        'alamat': alamat,
        'no_hp': no_hp,
        'email': email,
        'password': password,
        'level': level,
        'id_paket': id_paket,
        'id_teknisi': id_teknisi,
      },
    );
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['message'] == 'User updated successfully') {
        refreshData();
        fetchTotalUsers();
      } else {
        throw Exception('Failed to update user');
      }
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> addUser(String nama, String alamat, String no_hp,
      String id_paket, String id_teknisi,
      {String? id_mikrotik, String? profile}) async {
    // Default nomor HP jika kosong
    String nohp = no_hp.trim().isEmpty ? '00' : no_hp.trim();

    try {
      final response = await http
          .post(
            Uri.parse('http://aplikasi.bago.web.id/api/admin/tambah_pppoe.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user': nama,
              'pass': '1234',
              'profile': profile ?? '',
              'id_paket': id_paket,
              'id_teknisi': id_teknisi,
              'id_mikrotik': id_mikrotik ?? '',
              'alamat': alamat,
              'nohp': nohp,
            }),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          _showSnackBar(jsonResponse['message'] ?? 'User berhasil ditambahkan',
              Colors.green);
          // Refresh data setelah berhasil
          try {
            refreshData();
            fetchTotalUsers();
          } catch (_) {}
        } else {
          _showSnackBar(
              jsonResponse['message'] ?? 'Gagal menambahkan user', Colors.red);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      debugPrint('Error addUser: $e');
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Widget _buildUserCard(dynamic user, int index) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * (index + 1) * 0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showUserDetailBottomSheet(user),
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'user_${user['id_pelanggan']}',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user['nama'].toString().isNotEmpty
                                  ? user['nama'][0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user['nama'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Aktif',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              user['email'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            // First row of chips - balanced layout
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactInfoChip(
                                    icon: Icons.wifi_rounded,
                                    label: user['paket'] ?? 'Paket N/A',
                                    color: Colors.purple,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildCompactInfoChip(
                                    icon: Icons.payments_outlined,
                                    label:
                                        'Rp ${_formatCurrency(user['tarif'] ?? '0')}',
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            // Second row of chips - balanced layout
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactInfoChip(
                                    icon: Icons.location_on_outlined,
                                    label: user['alamat'].length > 12
                                        ? '${user['alamat'].substring(0, 12)}...'
                                        : user['alamat'],
                                    color: Colors.orange,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildCompactInfoChip(
                                    icon: Icons.phone_outlined,
                                    label: user['no_hp'],
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 16,
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
  }

  Widget _buildModernInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(dynamic user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showUserDetailBottomSheet(user),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'user_${user['id_pelanggan']}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.8),
                          Theme.of(context).primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user['nama'].toString().isNotEmpty
                            ? user['nama'][0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  user['nama'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  user['email'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                // Symmetric layout for info chips
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoChip(
                            icon: Icons.wifi_rounded,
                            label: user['paket'] ?? 'N/A',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoChip(
                            icon: Icons.payments_outlined,
                            label:
                                'Rp ${_formatCurrency(user['tarif'] ?? '0')}',
                            color: Colors.green,
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

  Widget _buildResponsiveTable(List<dynamic> users) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded,
                    color: Theme.of(context).primaryColor),
                SizedBox(width: 12),
                Text(
                  'Daftar Pengguna',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 28,
              horizontalMargin: 16,
              headingRowHeight: 56,
              dataRowHeight: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              columns: [
                DataColumn(
                  label: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'No.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nama Pengguna',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Paket Internet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Tagihan Bulanan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Alamat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
              rows: users.asMap().entries.map((entry) {
                int index = entry.key + 1;
                dynamic user = entry.value;
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          index.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      InkWell(
                        onTap: () => showUserDetailBottomSheet(user),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                child: Text(
                                  user['nama'].toString().isNotEmpty
                                      ? user['nama'][0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                user['nama'],
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user['paket'] ?? 'N/A',
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rp ${_formatCurrency(user['tarif'] ?? '0')}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: BoxConstraints(maxWidth: 150),
                        child: Text(
                          user['alamat'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveUserList(List<dynamic> users) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    final isDesktop = screenWidth > 1200;

    if (isDesktop || isTablet) {
      return _buildResponsiveTable(users);
    } else {
      return AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _isGridView
            ? Container(key: ValueKey('grid'), child: _buildGridView(users))
            : Container(key: ValueKey('list'), child: _buildListView(users)),
      );
    }
  }

  Widget _buildListView(List<dynamic> users) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 16),
      itemCount: users.length,
      itemBuilder: (context, idx) {
        int index = idx + 1;
        return _buildUserCard(users[idx], index);
      },
    );
  }

  Widget _buildGridView(List<dynamic> users) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 400 ? 2 : 1;

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: screenWidth > 400 ? 0.85 : 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildGridCard(users[index]);
      },
    );
  }

  Widget _buildStatsCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.5),
          child: Container(
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // Main stats row
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pelanggan Aktif',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$totalUsers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pengguna aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom actions row
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Filter: ${currentQuery.trim().isEmpty ? "Semua" : currentQuery.trim()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _isGridView
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'PPPOE Manager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(Icons.search_rounded, size: 22),
              ),
              tooltip: 'Cari Pengguna',
              onPressed: () async {
                final String? selected = await showSearch<String?>(
                  context: context,
                  delegate: UserSearch(_userList),
                );
                if (selected != null) {
                  filterUsers(selected);
                }
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(Icons.refresh_rounded, size: 22),
              ),
              tooltip: 'Refresh Data',
              onPressed: refreshData,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: refreshData,
          color: Theme.of(context).primaryColor,
          child: FutureBuilder<List<dynamic>>(
            future: _userListFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Memuat data pengguna...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Container(
                    margin: EdgeInsets.all(32),
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[600],
                            size: 48,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Oops! Terjadi kesalahan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tidak dapat memuat data pengguna. Silakan coba lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[600],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: refreshData,
                          icon: Icon(Icons.refresh_rounded),
                          label: Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                _userList = snapshot.data!;
                final filtered = _getFilteredUsers(_userList);
                return Column(
                  children: [
                    _buildStatsCard(),
                    Expanded(
                      child: filtered.isEmpty
                          ? (currentQuery.trim().isNotEmpty
                              ? Center(
                                  child: Container(
                                    margin: EdgeInsets.all(32),
                                    padding: EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.search_off_rounded,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          'Tidak ada hasil untuk "${currentQuery.trim()}"',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Coba kata kunci lain atau hapus filter pencarian',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Container(
                                    margin: EdgeInsets.all(32),
                                    padding: EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.people_outline_rounded,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          'Belum ada pengguna',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tambahkan pengguna pertama untuk memulai',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => showEditDialog(),
                                          icon: Icon(Icons.add_rounded),
                                          label: Text('Tambah Pengguna'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                          : _buildResponsiveUserList(filtered),
                    ),
                  ],
                );
              }
              return Center(
                child: Text(
                  'Tidak ada data untuk ditampilkan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => showEditDialog(),
            icon: Icon(Icons.add_rounded, size: 22),
            label: Text(
              'Tambah User',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            extendedPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class UserSearch extends SearchDelegate<String?> {
  final List<dynamic> userList;
  List<String> recentSearches = [];
  List<String> suggestions = [];

  UserSearch(this.userList);

  @override
  String get searchFieldLabel => 'Cari pengguna...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child:
                  Icon(Icons.clear_rounded, size: 18, color: Colors.grey[600]),
            ),
            onPressed: () {
              query = '';
              showSuggestions(context);
            },
            tooltip: 'Hapus pencarian',
          ),
        ),
      SizedBox(width: 8),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      child: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
        onPressed: () => close(context, null),
        tooltip: 'Kembali',
      ),
    );
  }

  @override
  void showResults(BuildContext context) {
    // Return the raw query to the caller for local filtering
    final q = query.trim();
    if (q.isNotEmpty && !recentSearches.contains(q)) {
      recentSearches.add(q);
    }
    close(context, q);
  }

  @override
  Widget buildResults(BuildContext context) {
    if (!recentSearches.contains(query) && query.trim().isNotEmpty) {
      recentSearches.add(query.trim());
    }

    String s(dynamic v) => (v ?? '').toString();
    final q = query.trim().toLowerCase();

    List<dynamic> filteredUsers = userList.where((user) {
      final nama = s(user['nama']).toLowerCase();
      final alamat = s(user['alamat']).toLowerCase();
      final noHp = s(user['no_hp']).toLowerCase();
      final email = s(user['email']).toLowerCase();
      final paket = s(user['paket']).toLowerCase();
      final id = s(user['id_pelanggan']).toLowerCase();
      return nama.contains(q) ||
          alamat.contains(q) ||
          noHp.contains(q) ||
          email.contains(q) ||
          paket.contains(q) ||
          id.contains(q);
    }).toList();

    return Container(
      color: Colors.grey[50],
      child: filteredUsers.isEmpty
          ? Center(
              child: Container(
                margin: EdgeInsets.all(32),
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ditemukan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Coba gunakan kata kunci lain',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.8),
                            Theme.of(context).primaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          s(user['nama']).isNotEmpty
                              ? s(user['nama'])[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      s(user['nama']).isEmpty
                          ? '(Tanpa nama)'
                          : s(user['nama']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(s(user['email'])),
                        SizedBox(height: 2),
                        Text(
                          s(user['no_hp']),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    onTap: () => close(context, query.trim()),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    String s(dynamic v) => (v ?? '').toString().trim();
    final q = query.trim().toLowerCase();

    String _bestLabel(dynamic u) {
      final candidates = [
        s(u['nama']),
        s(u['username']),
        s(u['email']),
        s(u['no_hp']),
        s(u['id_pelanggan']),
        s(u['paket']),
      ];
      return candidates.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    }

    final labels = userList
        .map((u) => _bestLabel(u))
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();

    suggestions = q.isEmpty
        ? recentSearches.toSet().toList()
        : labels
            .where((label) => label.toLowerCase().contains(q))
            .take(5)
            .toList();

    return Container(
      color: Colors.grey[50],
      child: suggestions.isEmpty
          ? Center(
              child: Container(
                margin: EdgeInsets.all(32),
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Mulai mengetik untuk mencari',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final isRecent = recentSearches.contains(suggestion);
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRecent
                            ? Colors.orange[100]
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isRecent
                            ? Icons.history_rounded
                            : Icons.person_outline_rounded,
                        color: isRecent
                            ? Colors.orange[600]
                            : Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    title: RichText(
                      text: TextSpan(
                        text: '',
                        style: DefaultTextStyle.of(context).style.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        children: _highlightMatches(
                          context,
                          suggestion,
                          q,
                          baseStyle: DefaultTextStyle.of(context)
                              .style
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: isRecent
                        ? Text(
                            'Pencarian terbaru',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () => close(context,
                        query.trim().isNotEmpty ? query.trim() : suggestion),
                  ),
                );
              },
            ),
    );
  }

  List<InlineSpan> _highlightMatches(
      BuildContext context, String text, String query,
      {TextStyle? baseStyle}) {
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

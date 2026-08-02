import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'edit_voucher.dart';

class UserResetForm extends StatefulWidget {
  @override
  _UserResetFormState createState() => _UserResetFormState();
}

class _UserResetFormState extends State<UserResetForm> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  String cabang2 = '';
  bool isLoading = false;
  int totalUsers = 0;

  Future<List<dynamic>> fetchUsers(String cabang) async {
    final response = await http
        .post(Uri.parse('http://aplikasi.bago.web.id/api/admin/user_bulanan.php'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        totalUsers = data.length;
      });
      return data;
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  void resetPassword(String username, String password) async {
    final url =
        Uri.parse('http://aplikasi.bago.web.id/api/admin/reset_voucher.php');
    final response = await http
        .post(url, body: {'username': username, 'password': password});
    if (response.statusCode == 200) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Reset Password'),
              content: Text('Password berhasil di reset'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          });
    } else {
      print('Failed to reset password for $username');
    }
  }

  void mac_reset(String username, String password) async {
    final url = Uri.parse('http://aplikasi.bago.web.id/api/admin/mac_reset.php');
    final response = await http
        .post(url, body: {'username': username, 'password': password});
    if (response.statusCode == 200) {
      SnackBar(
        content: Text('Reset password berhasil'),
        backgroundColor: Colors.green,
      );
    } else {
      print('Failed to reset password for $username');
    }
  }

  void matikan(String username, String password) async {
    final url = Uri.parse('http://aplikasi.bago.web.id/api/admin/matikan.php');
    final response = await http
        .post(url, body: {'username': username, 'password': password});
    if (response.statusCode == 200) {
      SnackBar(
        content: Text('Reset password berhasil'),
        backgroundColor: Colors.green,
      );
    } else {
      print('Failed to reset password for $username');
    }
  }

  void resetRanon(String username, String password) async {
    final url = Uri.parse('http://aplikasi.bago.web.id/api/api_ranon2/reset.php');
    final response = await http
        .post(url, body: {'username': username, 'password': password});
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset Ranon berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('Failed to reset ranon for $username');
    }
  }

  void deleteUser(String username) async {
    final url = Uri.parse(
        'http://aplikasi.bago.web.id/api/admin/de_user.php?username=$username');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Deleted User'),
            content: Text('User berhasil dihapus'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      print('Failed to delete user $username');
    }
  }

  Future<String?> getSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cabang = prefs.getString('nama');
    setState(() {
      cabang2 = cabang ?? '';
    });
    return cabang;
  }

  void _filterUsers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          filteredUsers = users;
        } else {
          filteredUsers = users.where((user) {
            return user['username'].toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      });
    });
  }

  Widget _openResetDialog(
      int id, String username, String password, String nohp) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan ikon dan judul
              Container(
                padding: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.blue[200]!, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.security,
                          color: Colors.blue[700], size: 28),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          'Kelola akun user dengan mudah',
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
              SizedBox(height: 20),

              // Informasi User
              Text(
                'Informasi User',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              _buildUserInfoItem('👤 Username', username),
              SizedBox(height: 10),
              _buildUserInfoItem('🔑 Password', password),
              SizedBox(height: 10),
              _buildUserInfoItem('📱 No. HP', nohp),
              SizedBox(height: 24),

              // Aksi yang tersedia
              Text(
                'Pilih Aksi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),

              // Tombol Reset
              _buildActionCard(
                icon: Icons.restart_alt_rounded,
                title: 'Reset Password',
                subtitle: 'Reset password user di sistem',
                color: Colors.red,
                onPressed: () {
                  resetPassword(username, password);
                },
              ),
              SizedBox(height: 10),

              // Tombol Mac Reset
              _buildActionCard(
                icon: Icons.router,
                title: 'Mac Reset',
                subtitle: 'Reset MAC address di router',
                color: Colors.grey[700]!,
                onPressed: () {
                  mac_reset(username, password);
                  showGeneralDialog(
                      context: context,
                      pageBuilder: (context, anim1, anim2) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Mac Reset Berhasil'),
                              ],
                            ),
                            content:
                                Text('Tunggu 1 menit untuk user login kembali'),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  matikan(username, password);
                                  Navigator.pop(context);
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ));
                },
              ),
              SizedBox(height: 10),

              // Tombol Reset Ranon
              _buildActionCard(
                icon: Icons.cloud_sync_rounded,
                title: 'Reset Ranon',
                subtitle: 'Reset sistem Ranon',
                color: Colors.blue,
                onPressed: () {
                  resetRanon(username, password);
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 10),

              // Tombol WhatsApp
              _buildActionCard(
                icon: Icons.chat_bubble_rounded,
                title: 'Kirim WhatsApp',
                subtitle: 'Notifikasi reset ke user',
                color: Color.fromARGB(255, 37, 211, 102),
                onPressed: () {
                  final kirim = Uri.parse(
                      "https://wa.me/$nohp?text=user anda sudah di reset, username: *$username*, password: *$password*, Silahkan login kembali, _jangan lupa ganti mac acak ke mac prangkat terlebih dahulu sebelum login kembali_ admin *Bago.net* ");
                  launchUrl(kirim, mode: LaunchMode.externalApplication);
                },
              ),
              SizedBox(height: 10),

              // Tombol Edit
              _buildActionCard(
                icon: Icons.edit_square,
                title: 'Edit User',
                subtitle: 'Ubah data user',
                color: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditUserForm(
                        id: id.toString(),
                        username: username,
                        password: password,
                        noHp: nohp,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),

              // Tombol Delete
              _buildActionCard(
                icon: Icons.delete_forever_rounded,
                title: 'Hapus User',
                subtitle: 'Hapus user dari sistem',
                color: Colors.redAccent,
                onPressed: () {
                  deleteUser(username);
                },
              ),
              SizedBox(height: 20),

              // Tombol Close
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, size: 20),
                  label: Text(
                    'Tutup',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.blue[900],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });

    getSharedPreferencesData().then((data) {
      String cabang = data ?? '';

      if (cabang == 'indra') {
        cabang2 = 'bago';
      } else if (cabang == 'MULYADI') {
        cabang2 = 'sentul';
      }

      fetchUsers(cabang2).then((data) {
        setState(() {
          users = data;
          filteredUsers = data; // Initialize filtered users
          isLoading = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Reset',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade900,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.0),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Total User: $totalUsers',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                });

                getSharedPreferencesData().then((data) {
                  String cabang = data ?? '';

                  if (cabang == 'indra') {
                    cabang2 = 'bago';
                  } else if (cabang == 'MULYADI') {
                    cabang2 = 'sentul';
                  }

                  fetchUsers(cabang2).then((data) {
                    setState(() {
                      users = data;
                      filteredUsers = data; // Reset filtered users
                      isLoading = false;
                    });
                  });
                });
              },
              icon: Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: searchController.text.isEmpty ? 60 : 70,
              child: TextField(
                controller: searchController,
                onChanged: _filterUsers,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Cari Username',
                  hintText: 'user bulanan',
                  labelStyle: TextStyle(
                      color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.blue.shade900,
                    size: 26,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            searchController.clear();
                            _filterUsers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : DataTable(
                      columnSpacing: 5.0,
                      headingRowColor: MaterialStateProperty.all(Colors.blue),
                      columns: [
                        DataColumn(
                            label: Text(
                          'No',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        )),
                        DataColumn(
                            label: Text(
                          'Username',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        )),
                        DataColumn(
                            label: Text(
                          'Password',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        )),
                        DataColumn(
                            label: Text(
                          'Cabang',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        )),
                      ],
                      rows: filteredUsers.asMap().entries.map<DataRow>(
                        (entry) {
                          int index = entry.key;
                          dynamic user = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _openResetDialog(
                                          int.parse(user['id']),
                                          user['username'],
                                          user['password'],
                                          user['no_hp'],
                                        );
                                      },
                                    );
                                  },
                                  child: Text(user['username']),
                                ),
                              ),
                              DataCell(Text(user['password'])),
                              DataCell(Text(user['cabang'])),
                            ],
                          );
                        },
                      ).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

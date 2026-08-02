import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';

import 'edit_voucher.dart';

class TAMBAH_BAYAR extends StatefulWidget {
  @override
  _TAMBAH_BAYARState createState() => _TAMBAH_BAYARState();
}

class _TAMBAH_BAYARState extends State<TAMBAH_BAYAR> {
  List<dynamic> users = [];
  TextEditingController searchController = TextEditingController();

  String cabang2 = '';
  bool isLoading = false;

  Future<List<dynamic>> fetchUsers(String cabang) async {
    final response = await http
        .post(Uri.parse('http://aplikasi.bago.web.id/api/admin/list_bayar.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  String _calculateExpirationDate(String daysUntilExpiration) {
    // Convert 'daysUntilExpiration' to integer
    int days = int.tryParse(daysUntilExpiration) ?? 0;

    // Calculate expiration date
    DateTime currentDate = DateTime.now();
    DateTime expirationDate = currentDate.add(Duration(days: days));

    // Format the expiration date (you can adjust the format as needed)
    String formattedExpirationDate =
        '${expirationDate.day}/${expirationDate.month}/${expirationDate.year}';

    return formattedExpirationDate;
  }

  void resetPassword(String username, String password) async {
    final url = Uri.parse('http://aplikasi.bago.web.id/api/admin/reset_bayar.php');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset password berhasil'),
          backgroundColor: Colors.green,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset password berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('Failed to reset password for $username');
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

  Widget _openResetDialog(
      int id, String username, String password, String nohp) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 5,
      backgroundColor: Colors.white,
      title: Text(
        'Reset Password',
        style: TextStyle(
          color: Colors.indigo.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username: $username',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
          SizedBox(height: 10.0),
          Text(
            'Password: ${password}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
          SizedBox(height: 10.0),
          Text(
            'No. HP: ${nohp}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
        ],
      ),
      actions: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    resetPassword(username, password);
                  },
                  icon: Icon(
                    Icons.reset_tv,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Reset',
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    elevation: 3,
                  ),
                ),
                SizedBox(width: 10.0),
                ElevatedButton.icon(
                  onPressed: () {
                    final kirim = Uri.parse(
                        "https://wa.me/$nohp?text=user anda sudah di reset, username: *$username*, password: *$password*, silahkan login paket bulanan anda, terima kasih *Bago.NET*");
                    launchUrl(kirim, mode: LaunchMode.externalApplication);
                  },
                  icon: Icon(Icons.chat, color: Colors.white, size: 20),
                  label: Text(
                    'WhatsApp',
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 3, 247, 129),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    elevation: 3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    mac_reset(username, password);
                    showGeneralDialog(
                        context: context,
                        pageBuilder: (context, anim1, anim2) => AlertDialog(
                              title: Text('Reset Password'),
                              content: Text(
                                  'Mac berhasil tunggu 1 menit untuk login kembali'),
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
                  icon: Icon(
                    Icons.mail,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Mac reset',
                    style: TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 87, 85, 86),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    elevation: 3,
                  ),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 18,
                    ),
                    label: Text(
                      'NON AKTIF',
                      style: TextStyle(color: Colors.black, fontSize: 14.0),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Color.fromARGB(255, 229, 255, 0)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0))),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0)),
                      elevation: MaterialStateProperty.all(3),
                    )),
              ],
            ),
            SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.exit_to_app, color: Colors.white, size: 18),
                  label: Text(
                    'Close',
                    style: TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    elevation: 3,
                  ),
                ),
                ElevatedButton.icon(
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
                  icon: Icon(Icons.edit, color: Colors.white, size: 18),
                  label: Text(
                    'EDIT',
                    style: TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ],
        )
      ],
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
          isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int n = 0;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        backgroundColor: Colors.indigo.shade800,
        title: Text(
          'BULANAN BERBAYAR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade900, Colors.indigo.shade700],
              stops: [0.1, 0.9],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
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
                    isLoading = false;
                  });
                });
              });
            },
            icon: Icon(Icons.refresh, color: Colors.white, size: 24),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddUserForm(),
                ),
              );
            },
            icon: Icon(Icons.add, color: Colors.white, size: 24),
            tooltip: 'Tambah Pengguna',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header informasi singkat
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.indigo.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Daftar Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Total Pengguna: ${users.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cabang: ${cabang2.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Klik pada kartu untuk mengelola akun pengguna',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Search',
                labelStyle: TextStyle(color: Colors.indigo.shade800),
                prefixIcon: Icon(Icons.search, color: Colors.indigo.shade800),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.indigo.shade800, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                hintText: 'Cari berdasarkan username...',
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.indigo.shade700),
                      SizedBox(height: 20),
                      Text(
                        'Memuat data pengguna...',
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ))
                : users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 48,
                              color: Colors.amber,
                            ),
                            Text(
                              'Tidak ada data pengguna ditemukan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: users
                            .where((user) =>
                                searchController.text.isEmpty ||
                                user['username'].toLowerCase().contains(
                                    searchController.text.toLowerCase()))
                            .length,
                        itemBuilder: (context, index) {
                          final filteredUsers = users
                              .where((user) =>
                                  searchController.text.isEmpty ||
                                  user['username'].toLowerCase().contains(
                                      searchController.text.toLowerCase()))
                              .toList();
                          final user = filteredUsers[index];

                          return FadeInUp(
                            duration:
                                Duration(milliseconds: 300 + (index * 80)),
                            child: Card(
                              margin: EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
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
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.indigo.shade50,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Username badge
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color:
                                                      Colors.indigo.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 18,
                                                  color: Colors.indigo.shade700,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  user['username'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.indigo.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Number badge
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Text(
                                              '#${filteredUsers.indexOf(user) + 1}',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      // Info grid
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            // Password row
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.vpn_key,
                                                  size: 16,
                                                  color: Colors.amber.shade700,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Password:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    user['password'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: 'monospace',
                                                      letterSpacing: 1,
                                                      color: Colors
                                                          .indigo.shade800,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(height: 16),
                                            // Date row
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.blue.shade700,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Tanggal:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  user['tanggal'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(height: 16),
                                            // Phone row
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone_android,
                                                  size: 16,
                                                  color: Colors.green.shade700,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'No. HP:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  user['no_hp'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade900,
                                                  ),
                                                ),
                                                Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    final kirim = Uri.parse(
                                                        "https://wa.me/${user['no_hp']}?text=Halo, pesan dari Bago.NET");
                                                    launchUrl(kirim,
                                                        mode: LaunchMode
                                                            .externalApplication);
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Container(
                                                    padding: EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.green.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Icon(
                                                      Icons.chat,
                                                      color:
                                                          Colors.green.shade700,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      // Action buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              resetPassword(user['username'],
                                                  user['password']);
                                            },
                                            icon: Icon(
                                              Icons.reset_tv,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'Reset',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade700,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.0,
                                                  vertical: 8.0),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditUserForm(
                                                    id: user['id'].toString(),
                                                    username: user['username'],
                                                    password: user['password'],
                                                    noHp: user['no_hp'],
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'Edit',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade700,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.0,
                                                  vertical: 8.0),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              mac_reset(user['username'],
                                                  user['password']);
                                            },
                                            icon: Icon(
                                              Icons.wifi,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'Mac Reset',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade700,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.0,
                                                  vertical: 8.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class AddUserForm extends StatefulWidget {
  @override
  _AddUserFormState createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController noHpController = TextEditingController();

  Future<void> _saveUser() async {
    // Data pengguna yang akan dikirimkan
    Map<String, String> userData = {
      'username': usernameController.text,
      'password': passwordController.text,
      'cabang': 'bayar_sentul',
      'no_hp': noHpController.text,
    };

    // Kirim permintaan HTTP POST ke URL
    final response = await http.post(
      Uri.parse('http://aplikasi.bago.web.id/api/admin/tambah_bulanan.php'),
      body: userData,
    );

    // Periksa kode status respons
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add User'),
            content: Text('Data pengguna berhasil disimpan'),
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
      // Gagal menyimpan data pengguna
      // Tambahkan logika sesuai kebutuhan Anda, misalnya menampilkan pesan kesalahan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add User'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: noHpController,
                decoration: InputDecoration(labelText: 'No. HP'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Panggil metode untuk menyimpan data pengguna
                  _saveUser();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                  textStyle:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

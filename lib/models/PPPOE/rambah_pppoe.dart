import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TambahForm extends StatefulWidget {
  const TambahForm({Key? key}) : super(key: key);
  @override
  _TambahFormState createState() => _TambahFormState();
}

class _TambahFormState extends State<TambahForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController namaController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController nohpController = TextEditingController();

  // Dropdown data
  List<Map<String, dynamic>> paketList = [];
  List<Map<String, dynamic>> teknisiList = [];
  List<Map<String, dynamic>> mikrotikList = [];
  List<String> profileList = [];

  String? selectedPaket;
  String? selectedTeknisi;
  String? selectedMikrotik;
  String? selectedProfile;

  // Harga paket yang dipilih
  double selectedHarga = 0;

  bool isLoading = false;
  bool isLoadingData = true;
  bool isLoadingProfile = false;

  final String baseUrl = 'http://aplikasi.bago.web.id/api/admin';

  // Warna tema ungu
  final Color primaryColor = Color(0xFF7C3AED);
  final Color lightPurple = Color(0xFFEDE9FE);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoadingData = true);
    await Future.wait([
      _fetchPaket(),
      _fetchTeknisi(),
      _fetchMikrotik(),
    ]);
    setState(() => isLoadingData = false);
  }

  Future<void> _fetchPaket() async {
    try {
      var url = Uri.parse('$baseUrl/paket.php');
      var response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          setState(() {
            paketList = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching paket: $e');
    }
  }

  Future<void> _fetchTeknisi() async {
    try {
      var url = Uri.parse('$baseUrl/teknisi.php');
      var response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          setState(() {
            teknisiList = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching teknisi: $e');
    }
  }

  Future<void> _fetchMikrotik() async {
    try {
      var url = Uri.parse('$baseUrl/mikrotik.php');
      var response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          setState(() {
            mikrotikList = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching mikrotik: $e');
    }
  }

  Future<void> _fetchProfiles(String mikrotikId) async {
    setState(() {
      isLoadingProfile = true;
      profileList = [];
      selectedProfile = null;
    });
    try {
      var url = Uri.parse(
          '$baseUrl/get_mikrotik_profiles.php?id_mikrotik=$mikrotikId');
      var response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success'] == true && data['profiles'] is List) {
          setState(() {
            profileList = List<String>.from(data['profiles']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
    }
    setState(() => isLoadingProfile = false);
  }

  // Update harga saat paket dipilih
  void _updateHarga(String? idPaket) {
    if (idPaket == null) {
      setState(() => selectedHarga = 0);
      return;
    }
    var paket = paketList.firstWhere(
      (p) => p['id_paket'].toString() == idPaket,
      orElse: () => {},
    );
    if (paket.isNotEmpty) {
      setState(() {
        selectedHarga = double.tryParse(paket['tarif'].toString()) ?? 0;
      });
    }
  }

  // Format harga ke Rupiah
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

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (selectedMikrotik == null) {
        _showErrorDialog('Pilih Mikrotik terlebih dahulu');
        return;
      }

      setState(() => isLoading = true);

      try {
        var url = Uri.parse('$baseUrl/tambah_pppoe.php');
        var response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'user': namaController.text,
                'pass': '1234',
                'profile': selectedProfile ?? '',
                'id_paket': selectedPaket,
                'id_teknisi': selectedTeknisi,
                'id_mikrotik': selectedMikrotik,
                'alamat': alamatController.text,
                'nohp': nohpController.text,
              }),
            )
            .timeout(Duration(seconds: 15));

        var data = json.decode(response.body);
        setState(() => isLoading = false);

        if (data['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(data['message'] ?? 'Berhasil!')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          _showErrorDialog(data['message'] ?? 'Gagal menambahkan data');
        }
      } catch (e) {
        setState(() => isLoading = false);
        _showErrorDialog('Error: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$hint harus diisi';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null) return '$hint harus dipilih';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE9D5FF),
              Color(0xFFF3E8FF),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoadingData
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Tambah Pengguna Baru',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Masukkan detail pengguna baru',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Nama Lengkap
                              _buildInputField(
                                controller: namaController,
                                hint: 'Nama Lengkap',
                                icon: Icons.person_outline,
                              ),

                              // Alamat
                              _buildInputField(
                                controller: alamatController,
                                hint: 'Alamat',
                                icon: Icons.location_on_outlined,
                              ),

                              // Nomor Telepon
                              _buildInputField(
                                controller: nohpController,
                                hint: 'Nomor Telepon',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),

                              // Paket Internet
                              _buildDropdownField(
                                hint: 'Paket Internet',
                                icon: Icons.wifi,
                                value: selectedPaket,
                                items: paketList.map((p) {
                                  double tarif =
                                      double.tryParse(p['tarif'].toString()) ??
                                          0;
                                  return DropdownMenuItem(
                                    value: p['id_paket'].toString(),
                                    child: Text(
                                        '${p['paket']} - ${_formatRupiah(tarif)}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => selectedPaket = val);
                                  _updateHarga(val);
                                },
                              ),

                              // Box Harga Paket
                              if (selectedPaket != null)
                                Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedHarga > 0
                                        ? Color(0xFFDCFCE7)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedHarga > 0
                                          ? Color(0xFF22C55E)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.payments_outlined,
                                        color: selectedHarga > 0
                                            ? Color(0xFF22C55E)
                                            : Colors.grey,
                                      ),
                                      SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Harga Paket:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            _formatRupiah(selectedHarga),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: selectedHarga > 0
                                                  ? Color(0xFF22C55E)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              // Mikrotik
                              _buildDropdownField(
                                hint: 'Pilih Mikrotik',
                                icon: Icons.router_outlined,
                                value: selectedMikrotik,
                                items: mikrotikList.map((m) {
                                  return DropdownMenuItem(
                                    value: m['id'].toString(),
                                    child: Text('${m['nama']} (${m['ip']})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => selectedMikrotik = val);
                                  if (val != null) {
                                    _fetchProfiles(val);
                                  }
                                },
                              ),

                              // Profile Mikrotik
                              if (selectedMikrotik != null)
                                isLoadingProfile
                                    ? Container(
                                        margin: EdgeInsets.only(bottom: 12),
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Memuat profile...'),
                                          ],
                                        ),
                                      )
                                    : _buildDropdownField(
                                        hint: 'Profile Mikrotik',
                                        icon: Icons.settings_ethernet,
                                        value: selectedProfile,
                                        items: profileList.map((p) {
                                          return DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(
                                            () => selectedProfile = val),
                                      ),

                              // Teknisi
                              _buildDropdownField(
                                hint: 'Teknisi',
                                icon: Icons.engineering_outlined,
                                value: selectedTeknisi,
                                items: teknisiList.map((t) {
                                  return DropdownMenuItem(
                                    value: t['id'].toString(),
                                    child: Text(t['nama'].toString()),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => selectedTeknisi = val),
                              ),

                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Buttons
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Batal Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, size: 18),
                              label: Text('Batal'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Tambah Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : submitForm,
                              icon: isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.add, size: 18),
                              label: Text(
                                isLoading ? 'Menyimpan...' : 'Tambah Pengguna',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
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
}

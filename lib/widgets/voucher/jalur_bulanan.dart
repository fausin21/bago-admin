import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

class JalurForm extends StatefulWidget {
  @override
  _JalurFormState createState() => _JalurFormState();
}

class _JalurFormState extends State<JalurForm> with TickerProviderStateMixin {
  List<dynamic> jalurList = [];
  String? cabang;
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredJalurList = [];
  String selectedLocation = 'Semua';
  List<String> locations = ['Semua'];

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Future<List<dynamic>> fetchJalurData() async {
    final response = await http.get(
      Uri.parse('http://aplikasi.bago.web.id/api/admin/jalur.php'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch jalur data');
    }
  }

  Future<String?> getSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama');
  }

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

    setState(() {
      isLoading = true;
    });

    getSharedPreferencesData().then((data) {
      setState(() {
        cabang = data;

        if (cabang == 'indra') {
          cabang = 'bago';
        } else if (data == 'MULYADI') {
          cabang = 'sentul';
        }
      });

      if (cabang != null) {
        fetchJalurData().then((data) {
          setState(() {
            jalurList = data;
            filteredJalurList = data;

            // Extract unique locations
            Set<String> locationSet = {'Semua'};
            for (var jalur in data) {
              if (jalur['location'] != null) {
                locationSet.add(jalur['location']);
              }
            }
            locations = locationSet.toList();

            // Initialize TabController
            _tabController =
                TabController(length: locations.length, vsync: this);
            _tabController.addListener(() {
              if (!_tabController.indexIsChanging) {
                filterByLocation(locations[_tabController.index]);
              }
            });

            isLoading = false;
          });
          _animationController.forward();
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void filterByLocation(String location) {
    setState(() {
      selectedLocation = location;
      if (location == 'Semua') {
        filteredJalurList = jalurList;
      } else {
        filteredJalurList =
            jalurList.where((jalur) => jalur['location'] == location).toList();
      }
      filterJalurList(searchController.text);
    });
  }

  void filterJalurList(String query) {
    List<dynamic> tempList = [];
    if (selectedLocation == 'Semua') {
      tempList.addAll(jalurList);
    } else {
      tempList.addAll(
          jalurList.where((jalur) => jalur['location'] == selectedLocation));
    }

    if (query.isNotEmpty) {
      List<dynamic> filteredList = [];
      tempList.forEach((jalur) {
        if (jalur['user'].toLowerCase().contains(query.toLowerCase()) ||
            jalur['status'].toLowerCase().contains(query.toLowerCase()) ||
            (jalur['cabang'] != null &&
                jalur['cabang'].toLowerCase().contains(query.toLowerCase()))) {
          filteredList.add(jalur);
        }
      });
      setState(() {
        filteredJalurList = filteredList;
      });
    } else {
      setState(() {
        filteredJalurList = tempList;
      });
    }
  }

  Future<void> matikanUser(String username) async {
    try {
      final response = await http.post(
        Uri.parse('http://aplikasi.bago.web.id/api/admin/matikan.php'),
        body: {'username': username},
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('User $username berhasil dimatikan');
        // Refresh data
        fetchJalurData().then((data) {
          setState(() {
            jalurList = data;
            filterByLocation(selectedLocation);
          });
        });
      } else {
        _showErrorSnackBar('Gagal mematikan user $username');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
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

  Widget _buildStatsCard() {
    int totalUsers = filteredJalurList.length;
    int activeUsers = filteredJalurList
        .where((jalur) =>
            jalur['status'].toLowerCase().contains('h') ||
            jalur['status'].toLowerCase().contains('m'))
        .length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
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
                    'Jalur Bulanan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    selectedLocation == 'Semua'
                        ? 'Semua Lokasi'
                        : selectedLocation.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$totalUsers User',
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
                  Icons.router,
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
              _buildStatItem('Online', '$activeUsers', Icons.wifi),
              _buildStatItem(
                  'Cabang', cabang?.toUpperCase() ?? '-', Icons.location_on),
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

  Widget _buildUserCard(dynamic jalur, int index) {
    String status = jalur['status'] ?? 'Unknown';
    String cabangName = jalur['cabang'] ?? 'Unknown';
    String location = jalur['location'] ?? 'Unknown';

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (status.toLowerCase().contains('h')) {
      statusColor = Colors.green;
      statusIcon = Icons.access_time;
      statusText = 'Online $status';
    } else if (status.toLowerCase().contains('m')) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Online $status';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.wifi_off;
      statusText = 'Offline';
    }

    return FadeInUp(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: Container(
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
                    backgroundColor: statusColor.withOpacity(0.2),
                    radius: 24,
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jalur['user'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cabang: $cabangName',
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
                    _buildDetailItem('Lokasi', location, Icons.location_on,
                        Colors.blue[600]!),
                    _buildDetailItem(
                        'Status', status, Icons.signal_wifi_4_bar, statusColor),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(jalur['user']),
                    icon: Icon(Icons.power_settings_new, size: 18),
                    label: Text('Matikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  void _showConfirmDialog(String username) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600]),
              SizedBox(width: 12),
              Text('Konfirmasi'),
            ],
          ),
          content: Text('Apakah Anda yakin ingin mematikan user "$username"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Batal'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                matikanUser(username);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Matikan'),
            ),
          ],
        );
      },
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
          'Jalur Bulanan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: locations.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.indigo[600],
                labelColor: Colors.indigo[600],
                unselectedLabelColor: Colors.grey[600],
                tabs: locations
                    .map((location) => Tab(
                          text: location == 'Semua'
                              ? 'Semua Lokasi'
                              : location.toUpperCase(),
                        ))
                    .toList(),
              )
            : null,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo[600]),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data jalur...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  final data = await fetchJalurData();
                  setState(() {
                    jalurList = data;
                    filterByLocation(selectedLocation);
                  });
                },
                child: Column(
                  children: [
                    _buildStatsCard(),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: filterJalurList,
                        decoration: InputDecoration(
                          hintText: 'Cari user, status, atau cabang...',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    filterJalurList('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: filteredJalurList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada data yang ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredJalurList.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(
                                    filteredJalurList[index], index);
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

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class UserAktif {
  final Map<String, int> servers;
  final int? total;
  final int? totalNonDbUsers;

  UserAktif({
    required this.servers,
    required this.total,
    required this.totalNonDbUsers,
  });

  factory UserAktif.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> serverData = json['servers'];
    final int? totalData = json['total'];
    final int? totalNonDb = json['total_non_db_users'];

    return UserAktif(
      servers: serverData.cast<String, int>(),
      total: totalData,
      totalNonDbUsers: totalNonDb,
    );
  }

  static Future<UserAktif> fetchData() async {
    final response = await http
        .get(Uri.parse('http://aplikasi.bago.web.id/api/admin/user_aktif.php'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return UserAktif.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}

class UserAktifScreen extends StatefulWidget {
  @override
  _UserAktifScreenState createState() => _UserAktifScreenState();
}

class _UserAktifScreenState extends State<UserAktifScreen> {
  late Future<UserAktif> _userAktifData;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _userAktifData = UserAktif.fetchData();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      refreshData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() {
      _userAktifData = UserAktif.fetchData();
    });
  }

  Color _getColorForCount(int count) {
    if (count < 100) {
      return Colors.red;
    } else if (count < 200) {
      return Colors.blue.shade200;
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        title: Text(
          'USER AKTIF',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FutureBuilder<UserAktif>(
        future: _userAktifData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userAktif = snapshot.data!;
            final serverEntries = userAktif.servers.entries.toList();

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(userAktif.total ?? 0),
                      duration: const Duration(seconds: 1),
                      tween: Tween<double>(
                        begin: 0,
                        end: userAktif.total?.toDouble() ?? 0,
                      ),
                      builder: (context, value, child) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'BAGO.NET',
                    key: ValueKey<String>('Total User Aktif'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 700,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final totalUsers =
                                  serverEntries[groupIndex].value;

                              return BarTooltipItem(
                                '$totalUsers',
                                const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    serverEntries[value.toInt()].key,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 100,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                        ),
                        barGroups: serverEntries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final serverData = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: serverData.value.toDouble(),
                                color: _getColorForCount(serverData.value),
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gojek_clone/widgets/voucher/detail_total_voucher.dart';

class SaldoScreen extends StatefulWidget {
  @override
  _SaldoScreenState createState() => _SaldoScreenState();
}

class _SaldoScreenState extends State<SaldoScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> saldoData = {"bulan": "", "data": {}};
  final Map<String, Color> serverColors = {};
  bool isLoading = true;
  late AnimationController _animationController;
  DateTime? lastFetchTime;
  final cacheKey = 'saldo_data_cache';
  final lastFetchKey = 'last_fetch_time';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _loadCachedData();
    fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    serverColors.clear();
    saldoData.clear();
    super.dispose();
  }

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    final lastFetchTimeStr = prefs.getString(lastFetchKey);

    if (cachedData != null) {
      setState(() {
        saldoData = json.decode(cachedData);
        _assignRandomColors();
        isLoading = false;
      });

      if (lastFetchTimeStr != null) {
        lastFetchTime = DateTime.parse(lastFetchTimeStr);
      }
    }
  }

  Future<void> _cacheData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, json.encode(data));
    await prefs.setString(lastFetchKey, DateTime.now().toIso8601String());
  }

  Future<void> fetchData() async {
    if (lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime!) < Duration(minutes: 5)) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('http://aplikasi.bago.web.id/api/admin/saldo.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        await _cacheData(responseData);

        setState(() {
          saldoData = responseData;
          _assignRandomColors();
          isLoading = false;
        });

        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _assignRandomColors() {
    final random = Random();
    for (var server in saldoData['data']?.keys ?? []) {
      if (!serverColors.containsKey(server)) {
        serverColors[server] = Color.fromRGBO(
          random.nextInt(100),
          random.nextInt(100),
          random.nextInt(100),
          1,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Saldo Server'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.purple,
                size: 50,
              ),
              SizedBox(height: 20),
              FadeIn(
                child: Text(
                  'Memuat data...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    int total = 0;
    int totalVoucher = 0;
    saldoData['data']?.forEach((key, value) {
      total += (value['total_penjualan'] ?? 0) as int;
      totalVoucher += (value['jumlah_voucher'] ?? 0) as int;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Saldo Server - ${saldoData['bulan']}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                lastFetchTime = null;
              });
              fetchData();
            },
            tooltip: 'Perbarui Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            lastFetchTime = null;
          });
          return fetchData();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4A148C),
                          Color(0xFF311B92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.bank, size: 24, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                currencyFormat.format(total),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$totalVoucher voucher terjual',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Detail per Daerah',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 8),
              if (totalVoucher == 0)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tidak Ada Data Penjualan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada voucher yang terjual pada bulan ${saldoData['bulan']}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: saldoData['data']?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  String daerah =
                      saldoData['data']?.keys.elementAt(index) ?? '';
                  var daerahData = saldoData['data']?[daerah];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                    child: BounceInLeft(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        color: serverColors[daerah] ?? Colors.grey[800],
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailVoucherScreen(
                                daerah: daerah,
                                namaDaerah: daerahData['nama_daerah'],
                                vouchers: daerahData['vouchers'] ?? [],
                              ),
                            ),
                          ),
                          splashColor: Colors.white.withOpacity(0.3),
                          highlightColor: Colors.white.withOpacity(0.1),
                          child: ListTile(
                            leading: Icon(Icons.computer,
                                size: 24, color: Colors.white),
                            title: Text(
                              daerahData['nama_daerah'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${daerahData['jumlah_voucher']} voucher',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              currencyFormat
                                  .format(daerahData['total_penjualan']),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Grafik Penjualan per Daerah',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 250,
                padding: EdgeInsets.all(12),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: saldoData['data']?.isEmpty ?? true
                        ? 0
                        : (saldoData['data']
                                ?.values
                                ?.map((e) => e['total_penjualan'] as int)
                                ?.reduce((a, b) => a > b ? a : b)
                                ?.toDouble() ??
                            0),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String daerah =
                              saldoData['data']?.keys.elementAt(groupIndex) ??
                                  '';
                          var daerahData = saldoData['data']?[daerah];
                          return BarTooltipItem(
                            '${daerahData['nama_daerah']}\n',
                            const TextStyle(color: Colors.white),
                            children: <TextSpan>[
                              TextSpan(
                                text: currencyFormat
                                    .format(daerahData['total_penjualan']),
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                            String daerah = saldoData['data']
                                    ?.keys
                                    .elementAt(value.toInt()) ??
                                '';
                            var daerahData = saldoData['data']?[daerah];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                daerahData['nama_daerah'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 35,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      saldoData['data']?.length ?? 0,
                      (index) {
                        String daerah =
                            saldoData['data']?.keys.elementAt(index) ?? '';
                        var daerahData = saldoData['data']?[daerah];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: daerahData['total_penjualan'].toDouble(),
                              color: serverColors[daerah] ?? Colors.blue,
                              width: 18,
                            ),
                          ],
                        );
                      },
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
}

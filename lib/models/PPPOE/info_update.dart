import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class NetworkMonitoringApp extends StatefulWidget {
  const NetworkMonitoringApp({Key? key}) : super(key: key);

  @override
  _NetworkMonitoringAppState createState() => _NetworkMonitoringAppState();
}

class _NetworkMonitoringAppState extends State<NetworkMonitoringApp>
    with TickerProviderStateMixin {
  List<NetworkPerformance> networkData = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _timer;
  bool _mounted = true;
  late AnimationController _scaleController;
  AnimationController? _valueController;
  late Animation<double> _scaleAnimation;
  List<Color> _textColors = [
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.indigo,
    Colors.pink,
    Colors.teal
  ];
  int _currentColorIndex = 0;
  Timer? _colorTimer;
  double _previousTxSpeed = 0;
  double _previousRxSpeed = 0;
  bool _initialLoadDone = false;
  DateTime _lastUpdateTime = DateTime.now();
  double _peakTxSpeed = 0;
  double _peakRxSpeed = 0;
  double _avgTxSpeed = 0;
  double _avgRxSpeed = 0;
  List<double> _txSpeedHistory = [];
  List<double> _rxSpeedHistory = [];
  int _totalConnections = 0;
  String _connectionStatus = 'Connecting...';
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _valueController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    _startColorAnimation();
    _fetchNetworkData();
    _startContinuousMonitoring();
  }

  void _startColorAnimation() {
    _colorTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _currentColorIndex = (_currentColorIndex + 1) % _textColors.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _timer?.cancel();
    _colorTimer?.cancel();
    _scaleController.dispose();
    _valueController?.dispose();
    super.dispose();
  }

  void _startContinuousMonitoring() {
    _timer = Timer.periodic(Duration(seconds: 3), (_) {
      if (_mounted) {
        _fetchNetworkData();
      }
    });
  }

  void _updateStatistics(double txSpeed, double rxSpeed) {
    _updateCount++;

    // Update peak speeds
    _peakTxSpeed = _peakTxSpeed < txSpeed ? txSpeed : _peakTxSpeed;
    _peakRxSpeed = _peakRxSpeed < rxSpeed ? rxSpeed : _peakRxSpeed;

    // Add to history (keep last 20 readings)
    _txSpeedHistory.add(txSpeed);
    _rxSpeedHistory.add(rxSpeed);
    if (_txSpeedHistory.length > 20) {
      _txSpeedHistory.removeAt(0);
      _rxSpeedHistory.removeAt(0);
    }

    // Calculate averages
    _avgTxSpeed =
        _txSpeedHistory.reduce((a, b) => a + b) / _txSpeedHistory.length;
    _avgRxSpeed =
        _rxSpeedHistory.reduce((a, b) => a + b) / _rxSpeedHistory.length;

    // Update connection status
    if (txSpeed > 0 || rxSpeed > 0) {
      _connectionStatus = 'Active';
    } else {
      _connectionStatus = 'Idle';
    }

    _totalConnections = networkData.length;
    _lastUpdateTime = DateTime.now();
  }

  Future<void> _fetchNetworkData() async {
    if (_isLoading || !_mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://aplikasi.bago.web.id/api/admin/info_all.php'),
        headers: {'Connection': 'keep-alive'},
      );

      if (!_mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final newData =
            jsonData.map((item) => NetworkPerformance.fromJson(item)).toList();

        if (!listEquals(networkData, newData)) {
          if (networkData.isNotEmpty && newData.isNotEmpty) {
            _previousTxSpeed = networkData[0].txSpeed;
            _previousRxSpeed = networkData[0].rxSpeed;

            if (networkData[0].txSpeed != newData[0].txSpeed ||
                networkData[0].rxSpeed != newData[0].rxSpeed) {
              _scaleController.forward().then((_) {
                _scaleController.reverse();
              });
              _valueController?.forward(from: 0.0);
            }
          } else {
            _previousTxSpeed = newData[0].txSpeed;
            _previousRxSpeed = newData[0].rxSpeed;
            _valueController?.forward(from: 0.0);
          }

          setState(() {
            networkData = newData;
            _initialLoadDone = true;
            if (newData.isNotEmpty) {
              _updateStatistics(newData[0].txSpeed, newData[0].rxSpeed);
            }
          });
        }
      } else {
        throw Exception('Failed to fetch network data');
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _connectionStatus = 'Error';
        });
      }
    } finally {
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatSpeed(double speed) {
    if (speed >= 1000) {
      return '${(speed / 1000).toStringAsFixed(2)} GB/s';
    } else {
      return '${speed.toStringAsFixed(2)} MB/s';
    }
  }

  String _formatBytes(double bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${bytes.toStringAsFixed(0)} B';
    }
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              'Status',
              _connectionStatus,
              Icons.signal_wifi_4_bar,
              _connectionStatus == 'Active'
                  ? Colors.green
                  : _connectionStatus == 'Idle'
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildInfoCard(
              'Last Update',
              DateFormat('HH:mm:ss').format(_lastUpdateTime),
              Icons.update,
              Colors.blue,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildInfoCard(
              'Updates',
              '$_updateCount',
              Icons.refresh,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDisplay(
      String label,
      double speed,
      double previousSpeed,
      Color iconColor,
      IconData icon,
      List<Color> gradientColors,
      double peakSpeed,
      double avgSpeed) {
    return FadeInDown(
      duration: Duration(milliseconds: 500),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 3,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: iconColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24),
                SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Main speed display (with animation)
            AnimatedBuilder(
              animation: _valueController ?? _scaleController,
              builder: (context, child) {
                final currentSpeed = previousSpeed +
                    (speed - previousSpeed) * (_valueController?.value ?? 0.0);
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      _formatSpeed(currentSpeed),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 10),
            Text(
              'CURRENT SPEED',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),

            SizedBox(height: 16),

            // Additional statistics
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Peak',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatSpeed(peakSpeed),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Text(
                        'Average',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatSpeed(avgSpeed),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator(NetworkPerformance performance) {
    final progress = (performance.txSpeed + performance.rxSpeed) / 3000;
    final totalSpeed = performance.txSpeed + performance.rxSpeed;

    return FadeInUp(
      duration: Duration(milliseconds: 600),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Bandwidth Usage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: progress > 0.7
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.7
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                    ),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Used: ${_formatSpeed(totalSpeed)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Max: 3.00 GB/s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Server info
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server IP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      performance.ip,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Monitoring Since',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(DateTime.now()
                          .subtract(Duration(seconds: _updateCount * 3))),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < "BAGO.NET".length; i++)
                  Text(
                    "BAGO.NET"[i],
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textColors[
                          (_currentColorIndex + i) % _textColors.length],
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        backgroundColor: Colors.indigo.shade800,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.network_check, color: Colors.white, size: 22),
            ),
            SizedBox(width: 10),
            Text(
              'Network Monitor',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade900, Colors.indigo.shade700],
              stops: [0.1, 0.9],
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: _fetchNetworkData,
            ),
          ),
        ],
      ),
      body: _isLoading && !_initialLoadDone
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.indigo.shade700,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading network data...',
                    style: TextStyle(
                      color: Colors.indigo.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : networkData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red.shade600,
                      ),
                      SizedBox(height: 20),
                      Text(
                        _errorMessage.isEmpty
                            ? 'No data available'
                            : _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchNetworkData,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      _buildStatisticsRow(),
                      _buildSpeedDisplay(
                        'Download',
                        networkData[0].txSpeed,
                        _previousTxSpeed,
                        Colors.blue.shade700,
                        Icons.download,
                        [Colors.blue.shade600, Colors.blue.shade900],
                        _peakTxSpeed,
                        _avgTxSpeed,
                      ),
                      _buildSpeedDisplay(
                        'Upload',
                        networkData[0].rxSpeed,
                        _previousRxSpeed,
                        Colors.green.shade700,
                        Icons.upload,
                        [Colors.green.shade600, Colors.green.shade900],
                        _peakRxSpeed,
                        _avgRxSpeed,
                      ),
                      _buildPerformanceIndicator(networkData[0]),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}

class NetworkPerformance {
  final String ip;
  final double txSpeed;
  final double rxSpeed;

  NetworkPerformance({
    required this.ip,
    required this.txSpeed,
    required this.rxSpeed,
  });

  factory NetworkPerformance.fromJson(Map<String, dynamic> json) {
    return NetworkPerformance(
      ip: json['ip'],
      txSpeed: (json['rx_speed'] as num).toDouble(),
      rxSpeed: (json['tx_speed'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkPerformance &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          txSpeed == other.txSpeed &&
          rxSpeed == other.rxSpeed;

  @override
  int get hashCode => ip.hashCode ^ txSpeed.hashCode ^ rxSpeed.hashCode;
}

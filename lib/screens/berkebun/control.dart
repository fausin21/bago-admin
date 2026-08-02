import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ControlPage extends StatefulWidget {
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage>
    with TickerProviderStateMixin {
  String status = 'off';
  double flowRate = 0;
  int timestamp = 0;
  bool isLoading = false;
  Timer? _timer;
  Timer? _flowCheckTimer;
  late AnimationController _pumpAnimationController;
  late AnimationController _fanAnimationController;
  late AnimationController _tempAnimationController;
  late Timer _clockTimer;
  late DateTime _currentTime;
  late bool _isDaytime;
  bool showFlowWarning = false;
  int _lastFlowUpdateTimestamp = 0;
  double temperature = 0;
  String fanStatus = 'off';
  String pumpStatus = 'off';
  int wifiSignal = 0;
  String wifiSignalCategory = '';

  final String pumpSvg = '''
<svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 122.88 122.07">
  <defs><style>.cls-1{fill-rule:evenodd;}</style></defs>
  <title>fan-blades</title>
  <path class="cls-1" d="M67.29,82.9c-.11,1.3-.26,2.6-.47,3.9-1.43,9-5.79,14.34-8.08,22.17C56,118.45,65.32,122.53,73.27,122A37.63,37.63,0,0,0,85,119a45,45,0,0,0,9.32-5.36c20.11-14.8,16-34.9-6.11-46.36a15,15,0,0,0-4.14-1.4,22,22,0,0,1-6,11.07l0,0A22.09,22.09,0,0,1,67.29,82.9ZM62.4,44.22a17.1,17.1,0,1,1-17.1,17.1,17.1,17.1,0,0,1,17.1-17.1ZM84.06,56.83c1.26.05,2.53.14,3.79.29,9.06,1,14.58,5.16,22.5,7.1,9.6,2.35,13.27-7.17,12.41-15.09a37.37,37.37,0,0,0-3.55-11.57,45.35,45.35,0,0,0-5.76-9.08C97.77,9,77.88,14,67.4,36.63a14.14,14.14,0,0,0-1,2.94A22,22,0,0,1,78,45.68l0,0a22.07,22.07,0,0,1,6,11.13Zm-26.9-17c0-1.6.13-3.21.31-4.81,1-9.07,5.12-14.6,7-22.52C66.86,2.89,57.32-.75,49.41.13A37.4,37.4,0,0,0,37.84,3.7a44.58,44.58,0,0,0-9.06,5.78C9.37,25.2,14.39,45.08,37,55.51a14.63,14.63,0,0,0,3.76,1.14A22.12,22.12,0,0,1,57.16,39.83ZM40.66,65.42a52.11,52.11,0,0,1-5.72-.24c-9.08-.88-14.67-4.92-22.62-6.73C2.68,56.25-.83,65.84.16,73.74A37.45,37.45,0,0,0,3.9,85.25a45.06,45.06,0,0,0,5.91,9c16,19.17,35.8,13.87,45.91-8.91a15.93,15.93,0,0,0,.88-2.66A22.15,22.15,0,0,1,40.66,65.42Z"/>
</svg>
  ''';

  final String fanSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12,11A1,1 0 0,0 11,12A1,1 0 0,0 12,13A1,1 0 0,0 13,12A1,1 0 0,0 12,11M12.5,2C17,2 17.11,5.57 14.75,6.75C13.76,7.24 13.32,8.29 13.13,9.22C13.61,9.42 14.03,9.73 14.35,10.13C18.05,8.13 22.03,8.92 22.03,12.5C22.03,17 18.46,17.1 17.28,14.73C16.78,13.74 15.72,13.3 14.79,13.11C14.59,13.59 14.28,14 13.88,14.34C15.87,18.03 15.08,22 11.5,22C7,22 6.91,18.42 9.27,17.24C10.25,16.75 10.69,15.71 10.89,14.79C10.4,14.59 9.97,14.27 9.65,13.87C5.96,15.85 2,15.07 2,11.5C2,7 5.56,6.89 6.74,9.26C7.24,10.25 8.29,10.68 9.22,10.87C9.41,10.39 9.73,9.97 10.14,9.65C8.15,5.96 8.94,2 12.5,2Z" />
</svg>
  ''';

  final String thermometerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M15 13V5A3 3 0 0 0 9 5V13A5 5 0 1 0 15 13M12 4A1 1 0 0 1 13 5V8H11V5A1 1 0 0 1 12 4Z" />
</svg>
  ''';

  @override
  void initState() {
    super.initState();
    getStatus();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => getStatus());
    _pumpAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tempAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _currentTime = DateTime.now();
    _isDaytime = _checkIfDaytime(_currentTime);
    _clockTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _isDaytime = _checkIfDaytime(_currentTime);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flowCheckTimer?.cancel();
    _pumpAnimationController.dispose();
    _fanAnimationController.dispose();
    _tempAnimationController.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  bool _checkIfDaytime(DateTime time) {
    return time.hour >= 6 && time.hour < 18;
  }

  Future<void> getStatus() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.99.200/monitor_api/api_on.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          status = data['status'] as String;
          if (data['latest_flow_data'] != null) {
            flowRate =
                (data['latest_flow_data']['flow_rate'] as num).toDouble();
            timestamp = data['latest_flow_data']['timestamp'] as int;
            _lastFlowUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
          }
          temperature = (data['temperature'] as num).toDouble();
          fanStatus = data['fan_status'] as String;
          pumpStatus = data['status'] as String;
          wifiSignal = data['wifi_signal'] as int;
          wifiSignalCategory = _categorizeWifiSignal(wifiSignal);
        });
        _updateAnimations();
        _startFlowCheck();
      } else {
        throw Exception('Gagal memuat status');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        status = 'error';
      });
    }
  }

  String _categorizeWifiSignal(int signal) {
    if (signal >= -50) {
      return 'Sangat Bagus';
    } else if (signal >= -60) {
      return 'Bagus';
    } else if (signal >= -70) {
      return 'Cukup';
    } else {
      return 'Buruk';
    }
  }

  void _updateAnimations() {
    if (pumpStatus.toLowerCase() == 'on') {
      _pumpAnimationController.repeat();
    } else {
      _pumpAnimationController.stop();
      _pumpAnimationController.animateTo(0);
    }

    if (fanStatus.toLowerCase() == 'on') {
      _fanAnimationController.repeat();
    } else {
      _fanAnimationController.stop();
      _fanAnimationController.animateTo(0);
    }

    _tempAnimationController.animateTo(temperature / 100);
  }

  Future<void> setStatus(String action) async {
    setState(() {
      isLoading = true;
      showFlowWarning = false;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.99.200/monitor_api/api_on.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response: ${response.body}'); // Tambahkan log

        setState(() {
          status = action;
          pumpStatus = action;
        });

        _updateAnimations();
        await getStatus(); // Refresh status setelah perubahan
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to change pump status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status pompa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startFlowCheck() {
    _flowCheckTimer?.cancel();
    _flowCheckTimer = Timer.periodic(Duration(seconds: 5), (_) {
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      if (currentTimestamp - _lastFlowUpdateTimestamp >= 30000) {
        setState(() {
          showFlowWarning = true;
        });
      } else {
        setState(() {
          showFlowWarning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[300]!, Colors.blue[100]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text('Kontrol Pompa Air',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildClockDisplay(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusDisplay(),
                          _buildFanDisplay(),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTemperatureCard(),
                          _buildFlowInfo(),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildWifiSignalInfo(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockDisplay() {
    return GlassmorphicContainer(
      width: 200,
      height: 80,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFffffff).withOpacity(0.1),
          Color(0xFFFFFFFF).withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFffffff).withOpacity(0.5),
          Color((0xFFFFFFFF)).withOpacity(0.5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
            color: _isDaytime ? Colors.orange : Colors.indigo,
            size: 30,
          ),
          SizedBox(width: 16),
          Text(
            '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    Color statusColor =
        pumpStatus.toLowerCase() == 'on' ? Colors.blue : Colors.red;
    String statusText = pumpStatus.toLowerCase() == 'on' ? 'HIDUP' : 'MATI';

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.1),
              ),
            ),
            RotationTransition(
              turns: _pumpAnimationController,
              child: SvgPicture.string(
                pumpSvg,
                width: 80,
                height: 80,
                color: statusColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Pompa: $statusText',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFanDisplay() {
    Color statusColor = fanStatus.toLowerCase() == 'on'
        ? Color.fromARGB(255, 2, 66, 18)
        : Colors.red;
    String statusText = fanStatus.toLowerCase() == 'on' ? 'HIDUP' : 'MATI';

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.1),
              ),
            ),
            RotationTransition(
              turns: _fanAnimationController,
              child: SvgPicture.string(
                fanSvg,
                width: 80,
                height: 80,
                color: statusColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Kipas: $statusText',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureCard() {
    return GlassmorphicContainer(
      width: 160,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFffffff).withOpacity(0.1),
          Color(0xFFFFFFFF).withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFffffff).withOpacity(0.5),
          Color((0xFFFFFFFF)).withOpacity(0.5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SUHU',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(
                thermometerSvg,
                width: 30,
                height: 30,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                '${temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowInfo() {
    return GlassmorphicContainer(
      width: 160,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFffffff).withOpacity(0.1),
          Color(0xFFFFFFFF).withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFffffff).withOpacity(0.5),
          Color((0xFFFFFFFF)).withOpacity(0.5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ALIRAN AIR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 30),
              SizedBox(width: 8),
              Text(
                '${flowRate.toStringAsFixed(2)} L/min',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (showFlowWarning) ...[
            SizedBox(height: 8),
            Text(
              'Tidak ada aliran air!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWifiSignalInfo() {
    Color signalColor;
    IconData signalIcon;

    if (wifiSignalCategory == 'Sangat Bagus') {
      signalColor = Color.fromARGB(255, 0, 0, 0);
      signalIcon = Icons.signal_wifi_4_bar;
    } else if (wifiSignalCategory == 'Bagus') {
      signalColor = const Color.fromARGB(255, 0, 0, 0);
      signalIcon = Icons.signal_wifi_4_bar;
    } else if (wifiSignalCategory == 'Cukup') {
      signalColor = Colors.orange;
      signalIcon = Icons.signal_wifi_0_bar_outlined;
    } else {
      signalColor = Colors.red;
      signalIcon = Icons.signal_wifi_4_bar_lock;
    }

    return GlassmorphicContainer(
      width: 140,
      height: 100,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.2),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SINYAL WIFI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(signalIcon, color: signalColor, size: 24),
              SizedBox(width: 8),
              Text(
                '$wifiSignal dBm',
                style: TextStyle(
                    fontSize: 18,
                    color: signalColor,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            wifiSignalCategory,
            style: TextStyle(
                fontSize: 14, color: signalColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AnimatedButton(
            onPress: isLoading ? null : () => setStatus('on'),
            height: 50,
            width: 150,
            text: 'Hidupkan',
            isReverse: true,
            selectedTextColor: Colors.green,
            transitionType: TransitionType.BOTTOM_TO_TOP,
            textStyle: TextStyle(
                fontSize: 18, color: const Color.fromARGB(255, 0, 0, 0)),
            backgroundColor: Colors.green,
            borderColor: Color.fromARGB(255, 68, 0, 255),
            borderRadius: 50,
            borderWidth: 2,
          ),
          AnimatedButton(
            onPress: isLoading ? null : () => setStatus('off'),
            height: 50,
            width: 150,
            text: 'Matikan',
            isReverse: true,
            selectedTextColor: Colors.red,
            transitionType: TransitionType.BOTTOM_TO_TOP,
            textStyle: TextStyle(fontSize: 18, color: Colors.white),
            backgroundColor: Colors.red,
            borderColor: Color.fromARGB(255, 255, 51, 0),
            borderRadius: 50,
            borderWidth: 2,
          ),
        ],
      ),
    );
  }
}

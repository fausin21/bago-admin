import 'dart:convert';
import 'package:http/http.dart' as http;

class ModelMikrotik {
  final String rxBits;
  final String txBits;
  final String cpuTemperature;
  final String temperature;

  ModelMikrotik({
    required this.rxBits,
    required this.txBits,
    required this.cpuTemperature,
    required this.temperature,
  });

  factory ModelMikrotik.fromJson(Map<String, dynamic> json) {
    return ModelMikrotik(
      rxBits: json['rx_bits'] ?? '',
      txBits: json['tx_bits'] ?? '',
      cpuTemperature: json['cpu_temperature'] ?? '',
      temperature: json['temperature'] ?? '',
    );
  }
}

class MikrotikData {
  final ModelMikrotik mikrotik1;
  final ModelMikrotik mikrotik2;

  MikrotikData({
    required this.mikrotik1,
    required this.mikrotik2,
  });

  factory MikrotikData.fromJson(Map<String, dynamic> json) {
    return MikrotikData(
      mikrotik1: ModelMikrotik.fromJson(json['mikrotik1']),
      mikrotik2: ModelMikrotik.fromJson(json['mikrotik2']),
    );
  }

  static Future<MikrotikData> ambilData() async {
    final response = await http
        .get(Uri.parse('http://192.168.99.200/monitor_api/api_mikrotik.php'));

    if (response.statusCode == 200) {
      return MikrotikData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengambil data Mikrotik');
    }
  }
}

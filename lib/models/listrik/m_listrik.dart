import 'dart:convert';
import 'package:http/http.dart' as http;

class ModelListrik {
  final Pzem pzem;
  final Dht11 dht11;

  ModelListrik({
    required this.pzem,
    required this.dht11,
  });

  factory ModelListrik.fromJson(Map<String, dynamic> json) {
    return ModelListrik(
      pzem: Pzem.fromJson(json['pzem']),
      dht11: Dht11.fromJson(json['dht11']),
    );
  }

  static Future<ModelListrik> ambilData() async {
    final response = await http
        .get(Uri.parse('http://192.168.99.200/monitor_api/ambil_data.php'));

    if (response.statusCode == 200) {
      return ModelListrik.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengambil data listrik');
    }
  }
}

class Pzem {
  final String voltage;
  final String current;
  final String power;
  final String energy;
  final String frequency;
  final String powerFactor;

  Pzem({
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.frequency,
    required this.powerFactor,
  });

  factory Pzem.fromJson(Map<String, dynamic> json) {
    return Pzem(
      voltage: json['voltage'],
      current: json['current'],
      power: json['power'],
      energy: json['energy'],
      frequency: json['frequency'],
      powerFactor: json['power_factor'],
    );
  }
}

class Dht11 {
  final String humidity;
  final String temperature;

  Dht11({
    required this.humidity,
    required this.temperature,
  });

  factory Dht11.fromJson(Map<String, dynamic> json) {
    return Dht11(
      humidity: json['humidity'],
      temperature: json['temperature'],
    );
  }
}

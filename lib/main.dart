import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gojek_clone/notifikasi/list_notifkasi.dart';
import 'package:gojek_clone/screens/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gojek_clone/network/network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<void> sendDeviceTokenToServer(
      String teknisiId, String deviceToken) async {
    final Uri url = Uri.parse('${Network.Url}/api/admin/token.php');

    try {
      final response = await http.post(
        url,
        body: {
          'nama': teknisiId,
          'token': deviceToken,
        },
      );

      if (response.statusCode == 200) {
        print('Device token successfully sent to the server.');
      } else {
        print(
            'Failed to send device token. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? teknisi_id = prefs.getString('nama');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class InboxApp extends StatelessWidget {
  const InboxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InboxScreen(),
    );
  }
}

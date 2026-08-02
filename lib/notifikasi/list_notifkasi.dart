import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> notifications = [];
  String nama = '';

  void getGopayBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? prefnama = prefs.getString('nama');
    setState(() {
      nama = prefnama!;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    // Ganti URL dan endpoint sesuai dengan backend Anda
    final idTeknisiUrl =
        'http://aplikasi.bago.web.id/api/admin/id_teknisi.php?nama=fausin';
    final notificationsUrl =
        'http://aplikasi.bago.web.id/api/admin/ambil_notif.php';

    try {
      // Step 1: Fetch technician ID
      final idTeknisiResponse = await http.get(Uri.parse(idTeknisiUrl));

      if (idTeknisiResponse.statusCode == 200) {
        final idTeknisiData = jsonDecode(idTeknisiResponse.body);
        final userId = idTeknisiData;
        // Assuming the ID is present in the response, adjust accordingly

        print('User ID: $userId');
        // Step 2: Fetch notifications using the obtained technician ID
        final notificationsResponse =
            await http.get(Uri.parse('$notificationsUrl?userid=$userId'));

        if (notificationsResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(notificationsResponse.body);
          setState(() {
            notifications = List<Map<String, dynamic>>.from(data);
          });
        } else {
          // Handle error response for fetching notifications
          print('Failed to load notifications');
        }
      } else {
        // Handle error response for fetching technician ID
        print('Failed to get technician ID');
      }
    } catch (error) {
      // Handle any exception that might occur during the HTTP requests
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
      ),
      body: Container(
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return ListTile(
              title: Text("Notifikasi"),
              subtitle: Text(notification['body']),
              // Tambahkan widget lain sesuai kebutuhan
            );
          },
        ),
      ),
    );
  }
}

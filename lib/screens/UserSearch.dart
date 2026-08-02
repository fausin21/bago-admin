import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gojek_clone/screens/tagihanBulanan.dart';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Import untuk menggunakan Clipboard

class SearchPage extends StatefulWidget {
  const SearchPage(
      {Key? key, required TagihanBulanan tagihanBulanan, required this.cari})
      : _tagihanBulanan = tagihanBulanan,
        super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
  final TagihanBulanan _tagihanBulanan; // Referensi ke TagihanBulanan
  final String cari;
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.cari);
    _search(widget.cari);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final response = await http.get(Uri.parse(
        'http://aplikasi.bago.web.id/api/admin/user_cari.php?search=$query'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(jsonData['data']);
      });
    } else {
      setState(() {
        _searchResults = [];
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch data: ${response.reasonPhrase}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _copyUserData(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone number copied to clipboard'),
      ),
      // Panggil metode refreshData
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      String username, String phoneNumber) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Action Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('What would you like to do with $username?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Copy'),
              onPressed: () {
                Navigator.of(context).pop();
                _copyUserData(phoneNumber);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(username);
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String username) async {
    final response = await http.get(Uri.parse(
        'http://aplikasi.bago.web.id/api/admin/de_user.php?username=$username'));

    if (response.statusCode == 200) {
      setState(() {
        _searchResults
            .removeWhere((userData) => userData['username'] == username);
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to delete user: ${response.reasonPhrase}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Enter username',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      final query = _searchController.text.trim();
                      if (query.isNotEmpty) {
                        _search(query);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Results: ${_searchResults.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                children: _searchResults.map((userData) {
                  return GestureDetector(
                    onTap: () {
                      _showDeleteConfirmationDialog(
                          userData['username'], userData['no_hp']);
                    },
                    child: Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Username: ${userData['username']}'),
                        subtitle: Text('No HP: ${userData['no_hp']}'),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

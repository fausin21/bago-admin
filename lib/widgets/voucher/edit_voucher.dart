import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditUserForm extends StatefulWidget {
  final String id;
  final String username;
  final String password;
  final String noHp;
  EditUserForm({
    required this.id,
    required this.username,
    required this.password,
    required this.noHp,
  });

  @override
  _EditUserFormState createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  TextEditingController idControlelr = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController noHpController = TextEditingController();
  void _editUser(
      String id, String username, String password, String noHp) async {
    final url = Uri.parse('http://aplikasi.bago.web.id/api/bago/edit_bulanan.php');
    final response = await http.post(url, body: {
      'id': id,
      'user': username,
      'password': password,
      'no_hp': noHp
    });
    if (response.statusCode == 200) {
      print(response.body);
    } else {
      // Gagal mengedit user
      print('Gagal mengedit user');
    }
  }

  @override
  void initState() {
    super.initState();

    // Mengisi nilai awal field-form sesuai data dari pengguna yang akan di-edit
    idControlelr.text = widget.id;
    usernameController.text = widget.username;
    passwordController.text = widget.password;
    noHpController.text = widget.noHp;
  }

  // TODO: Implement method to update user data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit User'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Flexible(
              child: TextField(
                controller: idControlelr,
                decoration: InputDecoration(
                  labelText: 'ID',
                  enabled: false,
                ),
              ),
            ),
            Flexible(
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  enabled: false,
                ),
              ),
            ),
            Flexible(
              child: TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
              ),
            ),
            Flexible(
              child: TextField(
                controller: noHpController,
                decoration: InputDecoration(labelText: 'No. HP'),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _editUser(
                  idControlelr.text,
                  usernameController.text,
                  passwordController.text,
                  noHpController.text,
                );
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

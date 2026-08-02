import 'package:flutter/material.dart';
import 'package:gojek_clone/screens/nav_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gojek_clone/network/network.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  static String tag = 'login-page';

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    if (username != null) {
      // Navigasi ke layar berikutnya jika sudah ada login sebelumnya
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NavScreen()));
    }
  }

  void _login() async {
    final url = '${Network.Url}/api/bago/login.php';

    final response = await http.post(Uri.parse(url), body: {
      "username": emailController.text,
      "password": passwordController.text
    });

    if (response.statusCode == 200) {
      if (response.body.toLowerCase().contains('error')) {
        // Menampilkan snackbar jika password salah
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      } else {
        // Menyimpan username dan nomer menggunakan SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('username', emailController.text);
        prefs.setString('nama', response.body);
        print(response.body);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => NavScreen()));
      }
    }

    print(response.body);
  }

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/images/logo.png')),
    );

    final email = TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      autofocus: false,
      decoration: InputDecoration(
        hintText: 'Phone Number',
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final password = TextFormField(
      controller: passwordController,
      autofocus: false,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'Password',
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.lightBlueAccent,
        ),
        onPressed: () {
          // jika user dan password kosong maka akan menampilkan pesan dan jika salah akan menampilkan pesan
          if (emailController.text.isEmpty || passwordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill all the fields')),
            );
          } else {
            _login();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Log In', style: TextStyle(color: Colors.white)),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            logo,
            SizedBox(height: 48.0),
            email,
            SizedBox(height: 8.0),
            password,
            SizedBox(height: 24.0),
            loginButton,
          ],
        ),
      ),
    );
  }
}

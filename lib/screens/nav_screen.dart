import 'package:flutter/material.dart';
import 'package:gojek_clone/screens/home.dart';
import 'package:gojek_clone/screens/genieacs.dart';
import 'package:gojek_clone/screens/sensor.dart';
import 'package:gojek_clone/screens/tagihanBulanan.dart';
import 'package:gojek_clone/widgets/voucher/tambah_voucher.dart';

class NavScreen extends StatefulWidget {
  @override
  _NavScreenState createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          Home(),
          TagihanBulanan(),
          GenieACSScreen(),
          //ucherOCRScreen(),
          TAMBAH_BAYAR(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor:
            Colors.black, // Mengubah warna ikon yang dipilih menjadi hitam
        unselectedItemColor: Colors.black.withOpacity(
            0.6), // Memberikan kesan transparansi pada ikon yang tidak dipilih
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dns),
            label: 'OLT',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_sharp),
            label: 'TAMBAH_BAYAR',
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gojek_clone/models/PPPOE/data_pppoe.dart';

import '../screens/aktif_pppoe.dart';
import 'PPPOE/rambah_pppoe.dart';
import 'PPPOE/tagihan_belum.dart';

class WalletIcons extends StatelessWidget {
  final IconData icons;
  final String text;
  final TextStyle textStyle;

  const WalletIcons(
      {required this.icons, required this.text, required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (text == 'TAGIHAN') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PppoePage()),
              );
            } else if (text == 'TAMBAH') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TambahForm()),
              );
            } else if (text == 'PPPOE \nAKTIF') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PppoeForm()),
              );
            } else if (text == 'TAGIHAN\n  PPPOE') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PppoePage()),
              );
            } else if (text == 'DATA\nPPPOE') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserTable()),
              );
            }
          },
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
              icons,
              size: 30,
              color: const Color(0xff0081A0),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12.0, fontStyle: FontStyle.italic),
        )
      ],
    );
  }
}

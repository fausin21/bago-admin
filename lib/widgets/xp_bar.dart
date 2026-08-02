import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class XpBar extends StatefulWidget {
  const XpBar({Key? key}) : super(key: key);

  @override
  State<XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<XpBar> {
  late Timer timer; // Deklarasikan variabel timer di sini

  DateTime currentTime = DateTime.now();
  double progress = 0.0;
  String greeting = '';

  @override
  void initState() {
    super.initState();
    // Mulai timer di dalam metode initState
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        currentTime = DateTime.now();
        progress = currentTime.second / 60;

        int hour = currentTime.hour;
        if (hour >= 0 && hour < 12) {
          greeting = 'Selamat Pagi';
        } else if (hour >= 12 && hour < 15) {
          greeting = 'Selamat Siang';
        } else if (hour >= 15 && hour < 18) {
          greeting = 'Selamat Sore';
        } else {
          greeting = 'Selamat Malam';
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel(); // Hentikan timer saat widget dihapus
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat.Hm().format(currentTime);
    String formattedDate = DateFormat.yMMMMd().format(currentTime);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.center,
          colors: [Color.fromARGB(255, 184, 241, 186), Colors.white],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/gocluppoinbar.png',
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
            ),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 45,
                  child: Image.asset(
                    'assets/images/GO-CLUB1.png',
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$formattedTime, $greeting',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: 245,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Container(
                          height: 4,
                          width: 245 * progress,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => print('GoClub XP'),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

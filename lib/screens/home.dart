import 'package:flutter/material.dart';

import 'package:gojek_clone/notifikasi/list_notifkasi.dart';
import 'package:gojek_clone/widgets/widgets.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        title: Center(
          child: Text(
            'BAGO.NET',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 15),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InboxScreen(),
                  ),
                );
                setState(() {
                  unreadNotificationsCount = 0;
                });
              },
              child: Stack(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    radius: 18,
                    child: Icon(
                      Icons.email,
                      color: Color(0xff00AA13),
                    ),
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$unreadNotificationsCount',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      // ===================== BODY ========================== //
      body: ListView(
        physics: ClampingScrollPhysics(),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: const [
                  SizedBox(
                    height: 15,
                  ),
                  Wallet(),
                  SizedBox(
                    height: 20,
                  ),
                  MainMenu(),
                  SizedBox(
                    height: 20,
                  ),
                  XpBar(),
                  SizedBox(
                    height: 15,
                  ),
                  // Wallet(),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Addition(),
              ),
              const SizedBox(
                height: 20,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'BAGO.NET',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                height: 30,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Banners(),
              ),
              Container(
                height: 20,
                color: Colors.transparent,
              )
            ],
          ),
        ],
      ),
    );
  }
}

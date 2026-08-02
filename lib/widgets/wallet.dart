import 'package:flutter/material.dart';
import 'package:gojek_clone/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Wallet extends StatefulWidget {
  const Wallet({Key? key}) : super(key: key);

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? gopayBalance = '';

  @override
  void initState() {
    super.initState();
    getGopayBalance();
  }

  void getGopayBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? balance = prefs.getString('nama');
    setState(() {
      gopayBalance = balance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff0081A0),
          borderRadius: BorderRadius.circular(25),
        ),
        height: 105,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        height: 75,
                        width: 125,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        height: 75,
                        width: 125,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.wallet_outlined,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  Text(
                                    'USERNAME',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(gopayBalance ?? 'Saldo masih kosong..',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const WalletIcons(
  icons: Icons.download,
  text: 'DATA\nPPPOE',
  textStyle: TextStyle(
    fontSize: 10.0,
      // Atur ukuran teks sesuai kebutuhan Anda
  ),
),
        const WalletIcons(
  icons: Icons.download,
  text: 'TAGIHAN\n  PPPOE',
  textStyle: TextStyle(
    fontSize: 10.0,
      // Atur ukuran teks sesuai kebutuhan Anda
  ),
),

           
            const WalletIcons(icons: Icons.rocket_launch, text: 'PPPOE \nAKTIF',
            textStyle: TextStyle(
              fontSize: 10.0,
            )
            
            ),
          ],
        ),
      ),
    );
  }
}

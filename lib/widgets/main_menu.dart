import 'package:flutter/material.dart';
import 'package:gojek_clone/card/setoran_akhir.dart';
import 'package:gojek_clone/olt/redaman.dart';
import 'package:gojek_clone/widgets/voucher/jalur_bulanan.dart';
import 'package:gojek_clone/widgets/voucher/tagihan_bulanan.dart';
import 'package:gojek_clone/widgets/voucher/total_saldo.dart';
import 'package:gojek_clone/widgets/voucher/user_aktif.dart';
import 'package:gojek_clone/widgets/voucher/user_bulanan.dart';

import '../models/PPPOE/info_update.dart';
import 'package:gojek_clone/screens/auto_isolir_screen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserResetForm(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/GoRide.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('RESET')
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TagihanBulananForm(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/GoCar.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('TAGIHAN')
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JalurForm(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/GoFood.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('JALUR')
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NetworkMonitoringApp(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/GoSend.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('Monitoring')
                ],
              ),
            ],
          ),
          // ================================================== //
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Column(
              //   children: [
              //     GestureDetector(
              //       onTap: () => print('GoMart'),
              //       child: Container(
              //         decoration: BoxDecoration(
              //             color: Colors.transparent,
              //             borderRadius: BorderRadius.circular(10)),
              //         height: 60,
              //         width: 60,
              //         child: Image.asset('assets/images/GoMart.png'),
              //       ),
              //     ),
              //     const SizedBox(
              //       height: 5,
              //     ),
              //     const Text('GoMart')
              //   ],
              // ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SaldoScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/GoPulsa.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('Saldo Voucher')
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetoranAkhir(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/rekap.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('Rekap Korwil')
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserAktifScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10)),
                      height: 60,
                      width: 60,
                      child: Image.asset('assets/images/account.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('UserAktif')
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // redaman_1
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RedamanForm(),
                        ),
                      );
                    },
                    child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 220, 228, 228),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        height: 50,
                        width: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 13,
                                    width: 13,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color:
                                            Color.fromARGB(255, 105, 109, 119)),
                                  ),
                                  const SizedBox(
                                    width: 3,
                                  ),
                                  Container(
                                    height: 13,
                                    width: 13,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color:
                                            Color.fromARGB(255, 105, 109, 119)),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    height: 13,
                                    width: 13,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color:
                                            Color.fromARGB(255, 105, 109, 119)),
                                  ),
                                  const SizedBox(
                                    width: 3,
                                  ),
                                  Container(
                                    height: 13,
                                    width: 13,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color:
                                            Color.fromARGB(255, 105, 109, 119)),
                                  )
                                ],
                              )
                            ],
                          ),
                        )),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('Redaman')
                ],
              ),
            ],
          ),
          // ================================================== //
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AutoIsolirScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(100),
                      ),
                      height: 50,
                      width: 50,
                      child: Icon(
                        Icons.timer_rounded,
                        color: Colors.orange[700],
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('Auto Isolir')
                ],
              ),
              const SizedBox(width: 60), // spacer
              const SizedBox(width: 60), // spacer
              const SizedBox(width: 60), // spacer
            ],
          ),
        ],
      ),
    );
  }
}

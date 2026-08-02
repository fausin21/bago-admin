import 'package:flutter/material.dart';
import 'package:gojek_clone/olt/odp_model.dart';
import 'package:gojek_clone/olt/redaman_data.dart';

class RedamanForm extends StatefulWidget {
  @override
  _RedamanFormState createState() => _RedamanFormState();
}

class _RedamanFormState extends State<RedamanForm> {
  final TextEditingController inputPowerController = TextEditingController();
  final TextEditingController rasio1Controller = TextEditingController();
  final TextEditingController rasio2Controller = TextEditingController();
  final TextEditingController insertLoss1Controller = TextEditingController();
  final TextEditingController insertLoss2Controller = TextEditingController();
  final TextEditingController distanceKmController =
      TextEditingController(text: '0');
  final TextEditingController connectorsController =
      TextEditingController(text: '2');
  final TextEditingController splicesController =
      TextEditingController(text: '4');
  final TextEditingController cityController = TextEditingController();
  final TextEditingController chainCountController =
      TextEditingController(text: '8');

  final List<SimulationResult> simulations = [];
  List<double> chainPowers = [];

  String redamanMasuk = '';
  String rasioText = '';
  String outputPower1 = '';
  String outputPower2 = '';
  String odp_rasio = '';
  String odp_non_rasio = '';
  List<ODP> odpList = [
    ODP(number: 2, port: 2, losSplitter: 3),
    ODP(number: 4, port: 4, losSplitter: 7),
    ODP(number: 8, port: 8, losSplitter: 10),
    ODP(number: 16, port: 16, losSplitter: 14),
    ODP(number: 32, port: 32, losSplitter: 17),
    ODP(number: 64, port: 64, losSplitter: 20),
    // Tambahkan objek ODP lainnya sesuai kebutuhan
  ];
  ODP? selectedODP; // ODP terpilih

  @override
  void dispose() {
    inputPowerController.dispose();
    rasio1Controller.dispose();
    rasio2Controller.dispose();
    insertLoss1Controller.dispose();
    insertLoss2Controller.dispose();
    distanceKmController.dispose();
    connectorsController.dispose();
    splicesController.dispose();
    cityController.dispose();
    chainCountController.dispose();
    super.dispose();
  }

  SimulationResult _computeSimulation(String cityName) {
    final double inputPower = double.tryParse(inputPowerController.text) ?? 0;
    final double? parsedAfterRatio = double.tryParse(outputPower1);
    final double afterRatioPower =
        (parsedAfterRatio != null && parsedAfterRatio.isFinite)
            ? parsedAfterRatio
            : inputPower;
    final double losSplitter = (selectedODP?.losSplitter ?? 0).toDouble();
    final double afterSplitter = afterRatioPower - losSplitter;

    final double connectorsLoss =
        (double.tryParse(connectorsController.text) ?? 0) * 0.5; // dB/konektor
    final double splicesLoss =
        (double.tryParse(splicesController.text) ?? 0) * 0.1; // dB/splice
    final double afterJoints = afterSplitter - connectorsLoss - splicesLoss;

    final double fiberLoss =
        (double.tryParse(distanceKmController.text) ?? 0) * 0.35; // dB/km
    final double afterFiber = afterJoints - fiberLoss;

    final stages = <double>[
      inputPower,
      afterRatioPower,
      afterSplitter,
      afterJoints,
      afterFiber,
    ];

    return SimulationResult(
      cityName:
          cityName.isEmpty ? 'Simulasi ${simulations.length + 1}' : cityName,
      odpNumber: selectedODP?.number ?? 0,
      stagePowers: stages,
    );
  }

  void _computeChainBackwards() {
    if (selectedODP == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih ODP terlebih dahulu')),
      );
      return;
    }

    final int count = int.tryParse(chainCountController.text) ?? 8;
    final double? parsedAfterRatio = double.tryParse(outputPower1);
    final double startPower =
        (parsedAfterRatio != null && parsedAfterRatio.isFinite)
            ? parsedAfterRatio
            : (double.tryParse(inputPowerController.text) ?? 0);

    final double totalKm = double.tryParse(distanceKmController.text) ?? 0;
    final double perStageKm = count > 0 ? totalKm / count : 0;
    final double totalConn = double.tryParse(connectorsController.text) ?? 0;
    final double perStageConn = count > 0 ? totalConn / count : 0;
    final double totalSplice = double.tryParse(splicesController.text) ?? 0;
    final double perStageSplice = count > 0 ? totalSplice / count : 0;

    final double losSplitter = (selectedODP!.losSplitter).toDouble();

    final List<double> powers = [startPower];
    double current = startPower;

    for (int i = 0; i < count; i++) {
      final double stepLoss = losSplitter +
          (perStageConn * 0.5) +
          (perStageSplice * 0.1) +
          (perStageKm * 0.35);
      current = current - stepLoss;
      powers.add(double.parse(current.toStringAsFixed(2)));
    }

    setState(() {
      chainPowers = powers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Redaman ODP'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: inputPowerController,
                decoration: InputDecoration(
                  labelText: 'Input Power',
                  prefixIcon: Icon(Icons.cloud),
                  suffix: Text(
                    'dBm',
                    style: TextStyle(fontSize: 16),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 16, // Atur ukuran teks label
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: rasio1Controller,
                          onChanged: (value) {
                            int rasio1 = int.tryParse(value) ?? 0;
                            int rasio2 = 100 - rasio1;
                            rasio2Controller.text = rasio2.toString();
                            if (rasio1 > 0 && rasio1 <= redamanList.length) {
                              insertLoss1Controller.text =
                                  redamanList[rasio1 - 1].redaman.toString();
                            }
                            if (rasio2 > 0 && rasio2 <= redamanList.length) {
                              insertLoss2Controller.text =
                                  redamanList[rasio2 - 1].redaman.toString();
                            }
                            setState(() {
                              rasioText = '$rasio1 : $rasio2';
                            });
                          },
                          decoration: InputDecoration(
                              labelText: 'Rasio', prefixIcon: Icon(Icons.info)),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: insertLoss1Controller,
                          enabled: false,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Insert Loss (Bagian 1)',
                            suffixIcon: Icon(Icons.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: rasio2Controller,
                          enabled: false,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Rasio',
                            suffixIcon: Icon(Icons.info),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: insertLoss2Controller,
                          enabled: false,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Insert Loss (Bagian 2)',
                            suffixIcon: Icon(Icons.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'Redaman perkiraan Jika tidak sesuai\nbisa di cek  kabel dan konektor\natau menggunakan alat OTDR  '),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.calculate),
                    label: Text(
                      'Hitung',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 238, 255, 0)),
                    onPressed: () {
                      double inputPower =
                          double.tryParse(inputPowerController.text) ?? 0;
                      double insertLoss1 =
                          double.tryParse(insertLoss1Controller.text) ?? 0;
                      double insertLoss2 =
                          double.tryParse(insertLoss2Controller.text) ?? 0;

                      setState(() {
                        redamanMasuk = inputPower.toString();
                        outputPower1 =
                            (inputPower - insertLoss1).toStringAsFixed(2);
                        outputPower2 =
                            (inputPower - insertLoss2).toStringAsFixed(2);
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Redaman Input:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Redaman Input:')),
                          Expanded(child: Text(redamanMasuk)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Text('RASIO:')),
                          Expanded(child: Text(rasioText)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Text('REDAMAN:')),
                          Expanded(child: Text(outputPower1)),
                          Expanded(child: Text(outputPower2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pilih Jenis ODP :  '),
                  Expanded(
                    child: DropdownButton<ODP>(
                      value: selectedODP,
                      onChanged: (ODP? newValue) {
                        setState(() {
                          selectedODP = newValue;
                        });
                      },
                      items: odpList.map<DropdownMenuItem<ODP>>((ODP odp) {
                        return DropdownMenuItem<ODP>(
                          value: odp,
                          child: Text(' Banding ${odp.number}'),
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedODP != null) {
                        double redaman = double.tryParse(outputPower1) ?? 0;
                        double losSplitter =
                            selectedODP!.losSplitter.toDouble();
                        double outputPower = redaman - losSplitter;
                        double redaman2 =
                            double.tryParse(inputPowerController.text) ?? 0;
                        double losSplitter2 =
                            selectedODP!.losSplitter.toDouble();
                        double outputPower2 = redaman2 - losSplitter2;

                        setState(() {
                          odp_rasio = outputPower.toStringAsFixed(2);
                          odp_non_rasio = outputPower2.toStringAsFixed(2);
                        });
                      } else {
                        // Show error message or handle the case when no ODP is selected
                      }
                    },
                    child: Text('Hitung'),
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('REDAMAN:')),
                          Expanded(
                              child: Text(odp_rasio,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                // double.parse(odp_non_rasio) >= -27.00

                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('REDAMAN TANPA RASIO :')),
                          Expanded(
                            child: Text(odp_non_rasio,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // --- Simulasi Section ---
              SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Simulasi Redaman (ODP / Kota)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: 'Nama Kota/Area (opsional)',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distanceKmController,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Panjang Kabel (km)',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: connectorsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Konektor',
                            prefixIcon: Icon(Icons.cable),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: splicesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Splice',
                            prefixIcon: Icon(Icons.merge),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chainCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah ODP berantai (default 8)',
                            prefixIcon: Icon(Icons.device_hub),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _computeChainBackwards,
                        child: Text('Hitung ODP ke Belakang'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Asumsi: 0.35 dB/km (SMF), 0.5 dB/konektor, 0.1 dB/splice',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.analytics),
                        onPressed: () {
                          if (selectedODP == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Pilih ODP terlebih dahulu')),
                            );
                            return;
                          }
                          final sim =
                              _computeSimulation(cityController.text.trim());
                          setState(() {
                            simulations.add(sim);
                          });
                        },
                        label: Text('Simulasikan & Simpan'),
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            simulations.clear();
                            chainPowers = [];
                          });
                        },
                        child: Text('Reset Simulasi'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (chainPowers.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil Perhitungan Berantai (${chainPowers.length - 1} ODP):',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Tahap')),
                                  DataColumn(label: Text('Power (dBm)')),
                                ],
                                rows: List.generate(chainPowers.length, (i) {
                                  final stageLabel =
                                      i == 0 ? 'Input' : 'ODP ${i}';
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(stageLabel)),
                                      DataCell(Text(
                                          chainPowers[i].toStringAsFixed(2))),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (simulations.isNotEmpty) ...[
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SimpleMultiLineChart(data: simulations),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: List.generate(simulations.length, (idx) {
                        final color = _ChartPainter.seriesColors[
                            idx % _ChartPainter.seriesColors.length];
                        final s = simulations[idx];
                        return Chip(
                          avatar: CircleAvatar(backgroundColor: color),
                          label: Text('${s.cityName} (ODP ${s.odpNumber})'),
                        );
                      }),
                    ),
                  ],
                ],
              ),
              // --- End Simulasi Section ---
            ],
          ),
        ),
      ),
    );
  }
}

class SimulationResult {
  final String cityName;
  final int odpNumber;
  final List<double>
      stagePowers; // [Input, After Ratio, After Splitter, After Joints, After Fiber]

  SimulationResult({
    required this.cityName,
    required this.odpNumber,
    required this.stagePowers,
  });
}

class SimpleMultiLineChart extends StatelessWidget {
  final List<SimulationResult> data;
  const SimpleMultiLineChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ChartPainter(data),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<SimulationResult> data;
  static const double padding = 28.0;
  static const List<String> stageLabels = [
    'Input',
    'Rasio',
    'Splitter',
    'Samb.',
    'Fiber'
  ];
  static const List<Color> seriesColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal
  ];

  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;

    final chartRect = Rect.fromLTWH(padding * 2, padding,
        size.width - padding * 3, size.height - padding * 2);

    // Axes
    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      paintAxis,
    );
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      paintAxis,
    );

    if (data.isEmpty) return;

    // Compute min/max
    double minY = data.first.stagePowers.first;
    double maxY = data.first.stagePowers.first;

    for (final s in data) {
      for (final v in s.stagePowers) {
        if (v.isFinite) {
          if (v < minY) minY = v;
          if (v > maxY) maxY = v;
        }
      }
    }

    if ((maxY - minY).abs() < 1e-6) {
      maxY += 1;
      minY -= 1;
    }

    double mapX(int index) {
      final step = chartRect.width / (stageLabels.length - 1);
      return chartRect.left + index * step;
    }

    double mapY(double value) {
      final t = (value - minY) / (maxY - minY);
      return chartRect.bottom - t * chartRect.height;
    }

    // Grid horizontal lines (3)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = chartRect.top + chartRect.height * i / 3;
      canvas.drawLine(
          Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Y labels (min, mid, max)
    final yVals = [minY, (minY + maxY) / 2, maxY];
    for (final yVal in yVals) {
      final y = mapY(yVal);
      textPainter.text = TextSpan(
          text: yVal.toStringAsFixed(1),
          style: TextStyle(fontSize: 10, color: Colors.black87));
      textPainter.layout();
      textPainter.paint(canvas, Offset(padding, y - textPainter.height / 2));
    }

    // X labels
    for (int i = 0; i < stageLabels.length; i++) {
      final x = mapX(i);
      textPainter.text = TextSpan(
          text: stageLabels[i],
          style: TextStyle(fontSize: 10, color: Colors.black87));
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, chartRect.bottom + 4));
    }

    // Draw series
    for (int si = 0; si < data.length; si++) {
      final s = data[si];
      final seriesPaint = Paint()
        ..color = seriesColors[si % seriesColors.length]
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < s.stagePowers.length; i++) {
        final x = mapX(i);
        final y = mapY(s.stagePowers[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, seriesPaint);

      // Draw points
      final fill = Paint()
        ..color = seriesPaint.color
        ..style = PaintingStyle.fill;
      for (int i = 0; i < s.stagePowers.length; i++) {
        final x = mapX(i);
        final y = mapY(s.stagePowers[i]);
        canvas.drawCircle(Offset(x, y), 3, fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

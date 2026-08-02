import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clipboard/clipboard.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class VoucherOCRScreen extends StatefulWidget {
  @override
  _VoucherOCRScreenState createState() => _VoucherOCRScreenState();
}

// Fixed: Making sure we're using TickerProviderStateMixin for multiple AnimationControllers
class _VoucherOCRScreenState extends State<VoucherOCRScreen>
    with TickerProviderStateMixin {
  String? _imagePath;
  List<VoucherData> _recognizedVouchers = [];
  String? _fullText;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isLoading = false;
  int _totalScans = 0;
  bool _showFullText = false;
  late TabController _tabController;
  bool _showScanAnimation = false;
  double _scanAnimationPosition = 0.0;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);

    // Setup scan line animation
    _scanLineController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation =
        Tween<double>(begin: 0, end: 1).animate(_scanLineController)
          ..addListener(() {
            setState(() {
              _scanAnimationPosition = _scanLineAnimation.value;
            });
          });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _tabController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _recognizedVouchers = [];
          _fullText = null;
          _totalScans++;
          _showScanAnimation = true;
        });
        await recognizeText();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> recognizeText() async {
    if (_imagePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delay to show the scan animation for a moment
      await Future.delayed(Duration(seconds: 2));

      final inputImage = InputImage.fromFilePath(_imagePath!);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String processedText = recognizedText.text;
      _fullText = processedText;

      List<VoucherData> vouchers = [];
      RegExp voucherRegex =
          RegExp(r'voucher\s+([a-zA-Z0-9]+)', caseSensitive: false);

      var matches = voucherRegex.allMatches(processedText.toLowerCase());
      for (var match in matches) {
        if (match.group(1) != null) {
          String voucher = match.group(1)!.toUpperCase();
          voucher = voucher.replaceAll(RegExp(r'[^A-Z0-9]'), '');
          // Skip if voucher contains BAGONET
          if (!voucher.contains('BAGONET')) {
            // Add voucher if length is more than 2 characters
            if (voucher.isNotEmpty &&
                voucher.length > 2 &&
                !vouchers.any((v) => v.code == voucher)) {
              vouchers.add(VoucherData(
                code: voucher,
                isVerified: false,
                dateFound: DateTime.now(),
              ));
            }
          }
        }
      }

      setState(() {
        _recognizedVouchers = vouchers;
        _isLoading = false;
        _showScanAnimation = false;

        // Switch to results tab
        if (_recognizedVouchers.isNotEmpty) {
          _tabController.animateTo(1);
        }
      });
    } catch (e) {
      print('Error recognizing text: $e');
      setState(() {
        _recognizedVouchers = [];
        _isLoading = false;
        _showScanAnimation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to recognize text'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void copyToClipboard(String text) {
    FlutterClipboard.copy(text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    });
  }

  void verifyVoucher(int index) {
    // This would typically connect to an API to verify the voucher
    // For now, we'll just simulate verification with a delay
    setState(() {
      _recognizedVouchers[index].isChecking = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _recognizedVouchers[index].isChecking = false;
        _recognizedVouchers[index].isVerified = true;
        // Random status for demo purposes
        _recognizedVouchers[index].status =
            ['Valid', 'Expired', 'Used', 'Valid'][index % 4];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCAN VOUCHER',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.camera_alt, color: Colors.white),
              child: Text('Scan', style: TextStyle(color: Colors.white)),
            ),
            Tab(
              icon: Icon(Icons.list_alt, color: Colors.white),
              child: Text('Results', style: TextStyle(color: Colors.white)),
            ),
          ],
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Voucher Scanner'),
                  content: Text(
                    'Ini adalah aplikasi untuk mengambil kode voucher dari gambar. '
                    ' ambil foto atau pilih gambar dari galeri untuk memindai kode voucher.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Scanner Tab
          buildScannerTab(),
          // Results Tab
          buildResultsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => getImage(ImageSource.camera),
              label: Text('Scan Now'),
              icon: Icon(Icons.document_scanner),
            )
          : null,
    );
  }

  Widget buildScannerTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Scan Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        icon: Icons.image,
                        value: '$_totalScans',
                        label: 'Total Scans',
                      ),
                      _buildStatCard(
                        icon: Icons.confirmation_number,
                        value: '${_recognizedVouchers.length}',
                        label: 'Vouchers Found',
                      ),
                      _buildStatCard(
                        icon: Icons.verified,
                        value:
                            '${_recognizedVouchers.where((v) => v.isVerified).length}',
                        label: 'Verified',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_imagePath != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  if (_showScanAnimation)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _scanAnimationPosition *
                          (Image.file(File(_imagePath!)).height ?? 300),
                      child: Container(
                        height: 2,
                        color: Colors.red.withOpacity(0.7),
                      ),
                    ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Processing Image...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: () => getImage(ImageSource.gallery),
                  icon: Icons.photo_library,
                  label: 'Pick Image',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  onPressed: () => getImage(ImageSource.camera),
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          if (_fullText != null) ...[
            SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Extracted Text',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFullText = !_showFullText;
                            });
                          },
                          icon: Icon(_showFullText
                              ? Icons.visibility_off
                              : Icons.visibility),
                          label: Text(_showFullText ? 'Hide' : 'Show'),
                        ),
                      ],
                    ),
                    if (_showFullText) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(_fullText!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildResultsTab() {
    return _recognizedVouchers.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No vouchers found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: Text('Go to Scanner'),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: _recognizedVouchers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final voucher = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(voucher.code),
                            IconButton(
                              icon: Icon(Icons.copy, size: 15),
                              onPressed: () => copyToClipboard(voucher.code),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        voucher.status != null
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(voucher.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  voucher.status!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : Text('-'),
                      ),
                      DataCell(
                        voucher.isChecking
                            ? CircularProgressIndicator(
                                strokeWidth: 2,
                              )
                            : ElevatedButton(
                                onPressed: voucher.isVerified
                                    ? null
                                    : () => verifyVoucher(index),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      voucher.isVerified
                                          ? Icons.check_circle
                                          : Icons.verified_user,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      voucher.isVerified
                                          ? 'Terverifikasi'
                                          : 'Verifikasi',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status) {
      case 'Valid':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      case 'Used':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class VoucherData {
  final String code;
  bool isVerified;
  bool isChecking;
  String? status;
  final DateTime dateFound;

  VoucherData({
    required this.code,
    this.isVerified = false,
    this.isChecking = false,
    this.status,
    required this.dateFound,
  });
}

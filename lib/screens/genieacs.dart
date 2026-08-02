import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:gojek_clone/network/network.dart';

class GenieACSScreen extends StatefulWidget {
  @override
  _GenieACSScreenState createState() => _GenieACSScreenState();
}

class _GenieACSScreenState extends State<GenieACSScreen> {
  List<dynamic> devices = [];
  List<dynamic> filteredDevices = [];
  bool isLoading = true;
  Timer? refreshTimer;
  TextEditingController searchController = TextEditingController();

  int totalDevices = 0;
  int onlineDevices = 0;
  int offlineDevices = 0;
  int unknownDevices = 0;

  @override
  void initState() {
    super.initState();
    fetchDevices();
    // Auto refresh setiap 30 detik
    refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchDevices();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDevices() async {
    try {
      final response = await http.get(
        Uri.parse('${Network.Url}/api/admin/olt.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (mounted) {
          setState(() {
            if (responseData['status'] == 'success') {
              devices = responseData['data'] ?? [];
              filteredDevices = devices;
              totalDevices = responseData['total_devices'] ?? 0;

              if (responseData['summary'] != null) {
                onlineDevices = responseData['summary']['online'] ?? 0;
                offlineDevices = responseData['summary']['offline'] ?? 0;
                unknownDevices = responseData['summary']['unknown'] ?? 0;
              }
            } else {
              devices = [];
              filteredDevices = devices;
            }
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching devices: $e');
    }
  }

  String getDeviceModel(dynamic device) {
    return device['device_id']?.toString() ?? 'Unknown Model';
  }

  String getDeviceStatus(dynamic device) {
    final status = device['status']?.toString().toLowerCase() ?? 'unknown';
    if (status == 'online') return 'Online';
    if (status == 'offline') return 'Offline';
    return 'Unknown';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Offline':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getLastInformTime(dynamic device) {
    return device['last_contact']?.toString() ?? 'N/A';
  }

  String getSignalStrength(dynamic device) {
    final rxPower = device['RXPower']?.toString();
    if (rxPower != null && rxPower != 'N/A' && rxPower.isNotEmpty) {
      try {
        final value = double.parse(rxPower);
        if (value > -10) return 'Excellent';
        if (value > -15) return 'Good';
        if (value > -20) return 'Fair';
        return 'Poor';
      } catch (e) {
        return 'Unknown';
      }
    }
    return 'N/A';
  }

  Color getSignalColor(String signal) {
    switch (signal) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void filterDevices(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDevices = devices;
      } else {
        filteredDevices = devices.where((device) {
          final deviceId = device['device_id']?.toString().toLowerCase() ?? '';
          final status = getDeviceStatus(device).toLowerCase();
          final ssid = device['SSID']?.toString().toLowerCase() ?? '';
          final primaryIp =
              device['primary_ip']?.toString().toLowerCase() ?? '';

          return deviceId.contains(query.toLowerCase()) ||
              status.contains(query.toLowerCase()) ||
              ssid.contains(query.toLowerCase()) ||
              primaryIp.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void showDeviceDetails(dynamic device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeviceDetailsSheet(device: device),
    );
  }

  void editWiFiName(dynamic device) {
    final currentSSID = device['SSID']?.toString() ?? 'Not Available';
    final controller = TextEditingController(
        text: currentSSID != 'Not Available' ? currentSSID : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit WiFi Name'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'WiFi Name (SSID)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter new WiFi name',
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementasi update WiFi name ke GenieACS
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 8),
                      Text('WiFi name updated successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void rebootDevice(dynamic device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reboot Device'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 40),
            SizedBox(height: 16),
            Text(
              'Are you sure you want to reboot this device?',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This action will temporarily disconnect the device.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementasi reboot device ke GenieACS
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.restart_alt, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Device reboot initiated'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Reboot'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'GenieACS Router Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchDevices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Routers',
                  totalDevices.toString(),
                  Icons.router,
                ),
                _buildStatItem(
                  'Online',
                  onlineDevices.toString(),
                  Icons.wifi,
                  Colors.green,
                ),
                _buildStatItem(
                  'Offline',
                  offlineDevices.toString(),
                  Icons.wifi_off,
                  Colors.red,
                ),
                _buildStatItem(
                  'Unknown',
                  unknownDevices.toString(),
                  Icons.help_outline,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: filterDevices,
              decoration: InputDecoration(
                hintText: 'Cari router, IP, atau WiFi name...',
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          filterDevices('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Device List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          'Loading devices...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : filteredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.router_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No devices found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchDevices,
                        color: Colors.blue,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];
                            return _buildDeviceCard(device);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      [Color? color]) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? Colors.white,
            size: 30,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(dynamic device) {
    final deviceId = device['device_id']?.toString() ?? 'Unknown';
    final model = getDeviceModel(device);
    final status = getDeviceStatus(device);
    final statusColor = getStatusColor(status);
    final primaryIp = device['primary_ip']?.toString() ?? 'N/A';
    final signalStrength = getSignalStrength(device);
    final signalColor = getSignalColor(signalStrength);
    final rxPower = device['RXPower']?.toString() ?? 'N/A';
    final lastContact = getLastInformTime(device);
    final ssid = device['SSID']?.toString() ?? 'Not Available';
    final activeDevices = device['activedevices']?.toString() ?? '0';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.router,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deviceId,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'IP: $primaryIp',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // WiFi Information Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'WiFi Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // SSID Row
                  Row(
                    children: [
                      Icon(Icons.network_wifi,
                          color: Colors.blue[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'SSID: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ssid,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Signal Row
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt,
                          color: signalColor, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Signal: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: signalColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: signalColor),
                        ),
                        child: Text(
                          signalStrength,
                          style: TextStyle(
                            color: signalColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Connected Devices Row
                  Row(
                    children: [
                      Icon(Icons.devices, color: Colors.green[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Connected: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$activeDevices devices',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Power Row
                  Row(
                    children: [
                      Icon(Icons.power, color: Colors.orange[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Power: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$rxPower dBm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Last Contact
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.grey[600], size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Last Contact: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lastContact,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => editWiFiName(device),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit WiFi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showDeviceDetails(device),
                    icon: Icon(Icons.info, size: 16),
                    label: Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => rebootDevice(device),
                    icon: Icon(Icons.restart_alt, size: 16),
                    label: Text('Reboot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceDetailsSheet extends StatelessWidget {
  final dynamic device;

  DeviceDetailsSheet({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Device Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Device Information', [
                    _buildDetailRow(
                        'Device ID', device['device_id']?.toString() ?? 'N/A'),
                    _buildDetailRow('Primary IP',
                        device['primary_ip']?.toString() ?? 'N/A'),
                    _buildDetailRow(
                        'Status', device['status']?.toString() ?? 'N/A'),
                    _buildDetailRow('Last Contact',
                        device['last_contact']?.toString() ?? 'N/A'),
                    _buildDetailRow('Last Inform Raw',
                        device['last_inform_raw']?.toString() ?? 'N/A'),
                  ]),
                  SizedBox(height: 20),
                  _buildSection('Network Information', [
                    _buildDetailRow('All IPs',
                        (device['all_ips'] as List?)?.join(', ') ?? 'N/A'),
                    _buildDetailRow('Primary IP',
                        device['primary_ip']?.toString() ?? 'N/A'),
                  ]),
                  SizedBox(height: 20),
                  _buildSection('WiFi Information', [
                    _buildDetailRow(
                        'SSID', device['SSID']?.toString() ?? 'N/A'),
                    _buildDetailRow('Active Devices',
                        device['activedevices']?.toString() ?? 'N/A'),
                  ]),
                  SizedBox(height: 20),
                  _buildSection('Signal Information', [
                    _buildDetailRow(
                        'RX Power', device['RXPower']?.toString() ?? 'N/A'),
                  ]),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[50]!, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

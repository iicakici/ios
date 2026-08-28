import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scanner App',
      home: const BleScanPage(),
    );
  }
}

class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  Future<void> startScan() async {
    setState(() {
      scanResults = [];
      isScanning = true;
    });

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Cihaz Tarayici'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isScanning ? null : startScan,
                child: Text(isScanning ? 'Taraniyor...' : 'Tara'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                final name = result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Bilinmeyen Cihaz';
                final id = result.device.remoteId.toString();
                final rssi = result.rssi;

                return ListTile(
                  title: Text(name),
                  subtitle: Text('$id ($rssi dBm)'),
                  trailing: const Icon(Icons.copy),
                  onTap: () {
                    // Panoya kopyala
                    final text = '$name - $id';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kopyalandi: $text')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

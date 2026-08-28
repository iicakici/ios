import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  String? errorMessage;
  String statusText = "Hazir";

  Future<void> startScan() async {
    setState(() {
      scanResults = [];
      isScanning = true;
      errorMessage = null;
      statusText = "Bluetooth durumu kontrol ediliyor...";
    });

    try {
      // Bilinmeyen (unknown) durumu atla, gercek durumu bekle
      final state = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 10));

      setState(() {
        statusText = "Adapter durumu: $state";
      });

      if (state != BluetoothAdapterState.on) {
        setState(() {
          errorMessage = "Bluetooth kapali veya izin verilmedi. Durum: $state";
          statusText = "Bluetooth hazir degil";
          isScanning = false;
        });
        return;
      }

      final sub = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });

      setState(() {
        statusText = "Tarama basliyor...";
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      setState(() {
        statusText = "Tarama bitti. ${scanResults.length} cihaz bulundu.";
      });

      await Future.delayed(const Duration(milliseconds: 500));
      sub.cancel();
    } catch (e, stack) {
      setState(() {
        errorMessage = "HATA: $e\n\nSTACK: $stack";
        statusText = "Hata olustu";
      });
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  bool _isAppleDevice(ScanResult result) {
    return result.advertisementData.manufacturerData.containsKey(76);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isScanning ? null : startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isScanning ? 'Taraniyor...' : 'Tara',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              statusText,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
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
                final isApple = _isAppleDevice(result);

                return ListTile(
                  leading: Icon(
                    isApple ? Icons.apple : Icons.bluetooth,
                    color: isApple ? Colors.black : Colors.blueGrey,
                    size: 28,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('$id ($rssi dBm)'),
                  trailing: const Icon(Icons.copy),
                  onTap: () {
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

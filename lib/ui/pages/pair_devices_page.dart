import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/widgets/custom_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/ui/pages/home_page.dart';

class PairDevicesPage extends StatefulWidget {
  const PairDevicesPage({super.key});

  @override
  State<PairDevicesPage> createState() => _PairDevicesPageState();
}

class _PairDevicesPageState extends State<PairDevicesPage> {
  FlutterBluePlus flutterBluePlus = FlutterBluePlus();
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectingDevice;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        scanResults.clear();
        isScanning = true;
      });
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        setState(() {
          for (ScanResult result in results) {
            if (!scanResults.any((element) =>
                element.device.remoteId == result.device.remoteId)) {
              scanResults.add(result);
            }
          }
        });
      }).onDone(() {
        setState(() {
          isScanning = false;
        });
      });
    } catch (e) {
      print("Error occurred during scanning: $e");
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        connectingDevice = device;
        isConnecting = true;
      });

      await device.connect(timeout: const Duration(seconds: 5));

      setState(() {
        isConnecting = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        isConnecting = false;
      });

      print("Failed to connect: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("connection_failed"))),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            tr("all_paired_up"),
            style: h1Text.copyWith(color: secondaryColor500),
            textAlign: TextAlign.center,
          ),
          content: Text(
            tr("start_translate_message"),
            style: bodyLText.copyWith(color: secondaryColor600),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: Text(tr("back")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(tr("start_translate")),
              onPressed: () {
                // Navigate to the HomePage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          CustomHeader(
            title: tr("pair_to_device"),
            leftIcon: Icons.arrow_back_ios_new,
            rightIcon: Icons.device_hub,
            color: whiteColor,
          ),
          _buildDeviceList(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: primaryColor500),
    );
  }

  Widget _buildDeviceList() {
    return Container(
      margin: const EdgeInsets.only(top: 120),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr("nearby_devices"),
            style: h2Text.copyWith(color: secondaryColor500),
          ),
          const SizedBox(height: 20),
          if (isScanning)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor500),
              ),
            ),
          const SizedBox(height: 20),
          if (scanResults.isEmpty && !isScanning)
            Center(
              child: Text(
                tr("no_devices_found"),
                style: bodyLText.copyWith(color: secondaryColor600),
              ),
            ),
          if (scanResults.isNotEmpty) _buildDeviceContainer(),
        ],
      ),
    );
  }

  Widget _buildDeviceContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor50,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: scanResults.map((result) {
          BluetoothDevice device = result.device;
          bool isThisDeviceConnecting =
              connectingDevice?.remoteId == device.remoteId && isConnecting;

          return GestureDetector(
            onTap: () {
              if (!isConnecting) {
                _connectToDevice(device);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: result != scanResults.last
                      ? BorderSide(color: secondaryColor600.withOpacity(0.5))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : tr("unnamed_device"),
                    style: bodyLText.copyWith(color: secondaryColor600),
                  ),
                  if (isThisDeviceConnecting)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

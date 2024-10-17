import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/widgets/custom_header.dart';

class PairDevicesPage extends StatefulWidget {
  const PairDevicesPage({super.key});

  @override
  State<PairDevicesPage> createState() => _PairDevicesPageState();
}

class _PairDevicesPageState extends State<PairDevicesPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

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

      await flutterBlue.startScan(timeout: const Duration(seconds: 4));

      flutterBlue.scanResults.listen((List<ScanResult> results) {
        setState(() {
          for (ScanResult result in results) {
            if (!scanResults.any((element) => element.device.id == result.device.id)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          CustomHeader(
            title: "Pair to other Device",
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
            "Nearby Devices",
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
                "No devices found.",
                style: bodyLText.copyWith(color: secondaryColor600),
              ),
            ),
          if (scanResults.isNotEmpty)
            _buildDeviceContainer(),
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
          return GestureDetector(
            onTap: () {
              // Handle device tap event, e.g., connect to the device
              print('Tapped on: ${result.device.name}');
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
              child: Text(
                result.device.name.isNotEmpty ? result.device.name : "Unnamed device",
                style: bodyLText.copyWith(color: secondaryColor600),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

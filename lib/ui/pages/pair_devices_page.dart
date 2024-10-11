import 'package:flutter/material.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/widgets/custom_header.dart';

class PairDevicesPage extends StatelessWidget {
  const PairDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> devices = [
      "Christine’s Ipad 11",
      "SAMSUNG TAB 234",
      "Ipad 10",
      "NJ’s Galaxy Tab",
      "cya"
    ];

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          CustomHeader(
              title: "Pair to other Device",
              leftIcon: Icons.arrow_back_ios_new,
              rightIcon: Icons.device_hub,
              color: whiteColor),
          _buildDeviceList(devices),
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

  Widget _buildDeviceList(List<String> devices) {
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
            "Devices",
            style: h2Text.copyWith(color: secondaryColor500),
          ),
          const SizedBox(height: 20),
          _buildDeviceContainer(devices),
        ],
      ),
    );
  }

  Widget _buildDeviceContainer(List<String> devices) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor50,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: devices.asMap().entries.map((entry) {
          int index = entry.key;
          String device = entry.value;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: index != devices.length - 1
                    ? BorderSide(color: secondaryColor600.withOpacity(0.5))
                    : BorderSide.none,
              ),
            ),
            child: Text(
              device,
              style: bodyLText.copyWith(color: secondaryColor600),
            ),
          );
        }).toList(),
      ),
    );
  }
}

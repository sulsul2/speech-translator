import 'package:flutter/material.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/pair_loading_page.dart';
import 'package:speech_translator/ui/widgets/custom_header.dart';
import 'package:easy_localization/easy_localization.dart';

class PairIntroPage extends StatefulWidget {
  const PairIntroPage({super.key});

  @override
  _PairIntroPageState createState() => _PairIntroPageState();
}

class _PairIntroPageState extends State<PairIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          CustomHeader(
              title: tr("pair_title"),
              leftIcon: Icons.arrow_back_ios_new,
              rightIcon: Icons.device_hub,
              color: secondaryColor500),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: whiteColor),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned.fill(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              tr("pair_instruction"),
              textAlign: TextAlign.center,
              style: bodyLText.copyWith(
                  color: secondaryColor400, fontWeight: regular, fontSize: 22),
            ),
          ),
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDeviceImage(),
                  const SizedBox(width: 64),
                  _buildDeviceImage(),
                ],
              ),
              _buildAnimatedBluetoothIcon(),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PairLoadingPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor500,
              padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr("start_searching"),
              style: bodyLText.copyWith(color: whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBluetoothIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: 220, 
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor500.withOpacity(0.2),
            ),
          ),
        ),
        ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.3).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor500.withOpacity(0.4),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor500,
          ),
          child: Icon(
            Icons.bluetooth_audio_rounded,
            color: whiteColor,
            size: 42,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceImage() {
    return Image.asset(
      'assets/ipad.png',
      width: 220,
      height: 300,
      fit: BoxFit.contain,
    );
  }
}

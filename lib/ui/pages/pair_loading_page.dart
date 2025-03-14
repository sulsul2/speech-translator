import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/widgets/custom_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'pair_devices_page.dart';

class PairLoadingPage extends StatefulWidget {
  const PairLoadingPage({super.key});

  @override
  _PairLoadingPageState createState() => _PairLoadingPageState();
}

class _PairLoadingPageState extends State<PairLoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startScanAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScanAndNavigate() async {
    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      await Future.delayed(const Duration(seconds: 5));

      FlutterBluePlus.stopScan();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PairDevicesPage(),
        ),
      );
    } catch (e) {
      print("Error occurred during scanning: $e");
    }
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
          _buildContent(),
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

  Widget _buildContent() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 400,
            height: 400,
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.3)),
              strokeWidth: 8,
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(400, 400),
                  painter: ArcPainter(),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr("searching_for"),
                  style: h1Text.copyWith(fontWeight: medium, color: whiteColor),
                ),
                Text(
                  tr("device_nearby"),
                  style: h1Text.copyWith(fontWeight: medium, color: whiteColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * 0.25;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

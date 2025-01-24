import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_qrcode_scanner/flutter_web_qrcode_scanner.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'package:speech_translator/services/firebase_services.dart';

import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/home_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

bool temp = false;

class _QrScannerPageState extends State<QrScannerPage> {
  final FirebaseService _firebaseService = FirebaseService();
  CameraController _controller = CameraController(autoPlay: true);
  bool _showQrCode = false;
  bool _showTokenSection = false;
  bool _showInputToken = false;

  // Add drag threshold to determine when to close
  double _dragStartPosition = 0;
  static const double _dragThreshold = 100;

  void _toggleQrCode(bool show) {
    setState(() {
      _showQrCode = show;
    });
  }

  void _toggleTokenSection(bool show) {
    setState(() {
      _showTokenSection = show;
    });
  }

  void _toggleInputToken(bool show) {
    setState(() {
      _showInputToken = show;
    });
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: FirebaseAuth.instance.currentUser?.uid ?? "No UID",
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Your QR code",
                style: h2Text.copyWith(color: secondaryColor500),
              ),
              Text(
                "Show this code to pair with other devices",
                style: bodyLText.copyWith(color: secondaryColor400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Close",
                  style: bodyLText.copyWith(color: whiteColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding:
              const EdgeInsets.only(left: 40, right: 40, top: 40, bottom: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 40),
          actionsPadding: const EdgeInsets.all(40),
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "All paired up!",
            style: h2Text.copyWith(color: secondaryColor500),
            textAlign: TextAlign.left,
          ),
          content: Text(
            "You can now start translating\ntogether with your partner",
            style: bodyLText.copyWith(
                color: secondaryColor500, fontWeight: regular, fontSize: 24),
            textAlign: TextAlign.left,
          ),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Back",
                      style: bodyLText.copyWith(
                          color: secondaryColor500, fontWeight: medium),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrScannerPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor500,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Start Translate",
                      style: bodyLText.copyWith(
                          color: whiteColor, fontWeight: medium),
                    ),
                    onPressed: () {
                      if (email.isNotEmpty) {
                        context
                            .read<PairedProvider>()
                            .updatePairedDevice(email);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "No UID";
    return Scaffold(
      body: Stack(
        children: [
          Container(
              color: Colors.black,
              child: FlutterWebQrcodeScanner(
                  cameraDirection: CameraDirection.back,
                  controller: _controller,
                  onGetResult: (result) async {
                    User? currentUser = FirebaseAuth.instance.currentUser;
                    await _firebaseService.sendPairingRequest(
                        currentUser!.uid, result);
                    String? email =
                        await _firebaseService.getEmailFromUid(result);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    _firebaseService.listenForPairingResponse(
                      result,
                      onAccepted: () {
                        _showSuccessDialog(email ?? "");
                        _controller.stopVideoStream();
                      },
                      onRejected: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Pairing request was rejected")),
                        );
                      },
                    );
                  })),
          Positioned(
            top: 60,
            left: 50,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(36),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: whiteColor,
                  size: 48,
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                  (Route<dynamic> route) => false,
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 50,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(36),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.flash_on_rounded,
                  color: whiteColor,
                  size: 48,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 77),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showQrCode = !_showQrCode; // Toggle state QR Code
                      });
                    },
                    child: Text(
                      "Show my QR code",
                      style: h1Text.copyWith(
                        color: secondaryColor500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showTokenSection =
                            !_showTokenSection; // Toggle state QR Code
                      });
                    },
                    child: Text(
                      "Pair using Token",
                      style: h1Text.copyWith(
                        color: secondaryColor500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // GestureDetector(
          //   onTap: _showQrCode ? () => _toggleQrCode(false) : null,
          //   child: Container(
          //     color: _showQrCode ? Colors.black54 : Colors.transparent,
          //     width: double.infinity,
          //     height: double.infinity,
          //   ),
          // ),

          // QR CODE
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            bottom: _showQrCode ? 0 : -600, // Muncul/tidak muncul
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragStart: (details) {
                _dragStartPosition = details.globalPosition.dy;
              },
              onVerticalDragUpdate: (details) {
                if (details.globalPosition.dy - _dragStartPosition >
                    _dragThreshold) {
                  _toggleQrCode(false);
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 600,
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 360,
                      height: 360,
                      child: QrImageView(
                        data: uid,
                        version: QrVersions.auto,
                        size: 360.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Your QR code",
                      style: h1Text.copyWith(
                          fontWeight: FontWeight.w800, color: primaryColor500),
                    ),
                    Text(
                      "Show this code to pair with other devices",
                      textAlign: TextAlign.center,
                      style: h2Text.copyWith(color: blackColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // TOKEN
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            bottom: _showTokenSection ? 0 : -600, // Muncul/tidak muncul
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragStart: (details) {
                _dragStartPosition = details.globalPosition.dy;
              },
              onVerticalDragUpdate: (details) {
                if (details.globalPosition.dy - _dragStartPosition >
                    _dragThreshold) {
                  _toggleTokenSection(false);
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 600,
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: _showInputToken
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Input token shown on other device",
                            style: h1Text.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontSize: 32),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Pinput(
                            length: 6,
                            defaultPinTheme: PinTheme(
                              width:
                                  MediaQuery.of(context).size.width * 0.4 / 6,
                              height: 100,
                              textStyle: h1Text,
                              decoration: BoxDecoration(
                                border: Border.all(color: blackColor),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onCompleted: (otp) {
                              print(otp);
                            },
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: primaryColor500),
                              onPressed: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 96, vertical: 20),
                                child: Text(
                                  "Pair",
                                  style: h2Text.copyWith(color: whiteColor),
                                ),
                              )),
                          const SizedBox(
                            height: 12,
                          ),
                          GestureDetector(
                            onTap: () => _toggleInputToken(false),
                            child: Text(
                              "See my token",
                              style: h2Text.copyWith(
                                  decoration: TextDecoration.underline,
                                  color: blackColor),
                            ),
                          )
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ST2315",
                            style: h1Text.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontSize: 120),
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          Text(
                            "Show this token to pair",
                            textAlign: TextAlign.center,
                            style: h1Text.copyWith(color: primaryColor500),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          GestureDetector(
                            onTap: () {
                              _toggleInputToken(true);
                            },
                            child: Text(
                              "Input token instead",
                              textAlign: TextAlign.center,
                              style: h2Text.copyWith(
                                  color: blackColor,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

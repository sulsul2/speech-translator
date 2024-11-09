import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_qrcode_scanner/flutter_web_qrcode_scanner.dart';
import 'package:provider/provider.dart';
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
                      Navigator.of(context).pop();
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
              color: Colors.black,
              child: FlutterWebQrcodeScanner(
                  cameraDirection: CameraDirection.back,
                  controller: _controller,
                  onGetResult: (result) async {
                    print(result);
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
                          SnackBar(
                              content: Text("Pairing request was rejected")),
                        );
                      },
                    );
                  })),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: whiteColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

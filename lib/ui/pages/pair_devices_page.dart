import 'package:flutter/material.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/widgets/custom_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/ui/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PairDevicesPage extends StatefulWidget {
  const PairDevicesPage({super.key});

  @override
  State<PairDevicesPage> createState() => _PairDevicesPageState();
}

class _PairDevicesPageState extends State<PairDevicesPage> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, String> emailsAndUids = {};
  bool isLoading = false;
  bool isSendingRequest = false;
  String? connectedUserUid;

  @override
  void initState() {
    super.initState();
    _fetchEmailsAndUids();
  }

  Future<void> _fetchEmailsAndUids() async {
    try {
      setState(() {
        isLoading = true;
      });

      Map<String, String> fetchedEmailsAndUids =
          await _firebaseService.fetchAllEmailsAndUids();

      User? currentUser = FirebaseAuth.instance.currentUser;
      fetchedEmailsAndUids.remove(currentUser?.uid);

      setState(() {
        emailsAndUids = fetchedEmailsAndUids;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching emails and UIDs: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendPairingRequest(String uid, String email) async {
    setState(() {
      isSendingRequest = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;

    try {
      await _firebaseService.sendPairingRequest(currentUser!.uid, uid);

      _firebaseService.listenForPairingResponse(uid, onAccepted: () {
        setState(() {
          isSendingRequest = false;
          connectedUserUid = uid;
        });
        _showSuccessDialog(email);
      }, onRejected: () {
        setState(() {
          isSendingRequest = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("pairing_rejected"))),
        );
      });
    } catch (e) {
      setState(() {
        isSendingRequest = false;
      });

      print("Failed to send pairing request: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("failed_to_pair"))),
      );
    }
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
                        color: secondaryColor500,
                        fontWeight: medium,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
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
                        color: whiteColor,
                        fontWeight: medium,
                      ),
                    ),
                    onPressed: () {
                      if (email.isNotEmpty) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(paired: email),
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
          _buildBackground(),
          CustomHeader(
            title: tr("pair_to_device"),
            leftIcon: Icons.arrow_back_ios_new,
            rightIcon: Icons.device_hub,
            color: whiteColor,
          ),
          _buildEmailList(),
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

  Widget _buildEmailList() {
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
            tr("nearby_users"),
            style: h2Text.copyWith(color: secondaryColor500),
          ),
          const SizedBox(height: 20),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor500),
              ),
            ),
          const SizedBox(height: 20),
          if (emailsAndUids.isEmpty && !isLoading)
            Center(
              child: Text(
                tr("no_users_found"),
                style: bodyLText.copyWith(color: secondaryColor600),
              ),
            ),
          if (emailsAndUids.isNotEmpty) _buildEmailContainer(),
        ],
      ),
    );
  }

  Widget _buildEmailContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor50,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: emailsAndUids.entries.map((entry) {
          String email = entry.value;
          String uid = entry.key;
          return GestureDetector(
            onTap: () {
              if (!isSendingRequest && connectedUserUid == null) {
                _sendPairingRequest(uid, email);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: email != emailsAndUids.values.last
                      ? BorderSide(color: secondaryColor600.withOpacity(0.5))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    email,
                    style: bodyLText.copyWith(color: secondaryColor600),
                  ),
                  if (isSendingRequest && connectedUserUid == null)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  else if (connectedUserUid == uid)
                    Text(
                      "Connected",
                      style: bodyLText.copyWith(color: secondaryColor300),
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

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'package:speech_translator/providers/speech_provider.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/forget_password_page.dart';
import 'package:speech_translator/ui/pages/history_page.dart';
import 'package:speech_translator/ui/pages/qr_scanner_page.dart';
import 'package:speech_translator/ui/pages/translate_page.dart';
import 'package:speech_translator/ui/pages/welcome_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController editableController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String selectedLanguage = "Bahasa Indonesia";

  final List<Map<String, String>> languages = [
    {"name": "Bahasa Indonesia", "icon": "assets/flag_ind.png", "locale": "id"},
    {"name": "English", "icon": "assets/flag_en.png", "locale": "en"},
    {"name": "日本語", "icon": "assets/flag_jap.png", "locale": "ja"},
    {"name": "廣東話", "icon": "assets/flag_hk.png", "locale": "zh_HK"},
  ];
  late PairedProvider pairedProvider;
  bool isDropdownOpen = false;
  // bool isToUid = false;

  @override
  void initState() {
    super.initState();

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      _firebaseService
          .listenForPairingRequests(currentUser.uid, context)
          .listen((result) {
        setState(() {
          print(result);
          pairedProvider.updateIsToUid(result);
          // isToUid = result;
          // print(isToUid);
        });
      });
      // print(isToUid);
    }
  }

  getInit() {
    pairedProvider = Provider.of<PairedProvider>(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setLanguageFromLocale();
    getInit();
  }

  void _setLanguageFromLocale() {
    final currentLocale = context.locale.toString();
    final selectedLang = languages.firstWhere(
      (language) => language['locale'] == currentLocale,
      orElse: () => languages.first,
    );

    setState(() {
      selectedLanguage = selectedLang['name']!;
    });
  }

  Locale _getLocaleFromLang(String localeCode) {
    switch (localeCode) {
      case 'id':
        return const Locale('id');
      case 'en':
        return const Locale('en');
      case 'ja':
        return const Locale('ja');
      case 'zh_HK':
        return const Locale('zh', 'HK');
      default:
        return const Locale('en');
    }
  }

  void _showLogoutDialog(BuildContext context) {
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
            "Log out",
            style: h2Text.copyWith(color: secondaryColor500),
            textAlign: TextAlign.left,
          ),
          content: Text(
            "Are you sure want to log out?",
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
                      "Cancel",
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
                      backgroundColor: errorColor500,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Log Out",
                      style: bodyLText.copyWith(
                        color: whiteColor,
                        fontWeight: medium,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout(context);
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

  Future<void> _scanQRCode() async {
    try {
      final scanResult = await BarcodeScanner.scan();
      if (scanResult.rawContent.isNotEmpty) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        await _firebaseService.sendPairingRequest(
            currentUser!.uid, scanResult.rawContent);
      }
    } catch (e) {
      print("Failed to scan QR Code: $e");
    }
  }

  void _showQRDialog(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? 'No UID found';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.only(top: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Your QR Code",
            textAlign: TextAlign.center,
            style: bodyLText.copyWith(fontWeight: bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: uid,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Scan this code to pair with another device",
                  textAlign: TextAlign.center,
                  style: bodyMText,
                ),
              ],
            ),
          ),
          // actions: [
          //   Center(
          //     child: ElevatedButton(
          //       onPressed: () {
          //         Navigator.of(context).pop();
          //       },
          //       child: Text("Close"),
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //       ),
          //     ),
          //   ),
          // ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      context.read<PairedProvider>().updatePairedDevice('');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage()),
        (route) => false,
      );
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log out. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SpeechState speechState = Provider.of<SpeechState>(context);
    final paired = context.watch<PairedProvider>().pairedDevice;
    User? user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? "User";

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 40,
            left: 100,
            right: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isDropdownOpen = !isDropdownOpen;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isDropdownOpen ? 252 : 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: isDropdownOpen
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          languages.firstWhere(
                            (lang) => lang["name"] == selectedLanguage,
                            orElse: () => languages.first,
                          )["icon"]!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                        if (isDropdownOpen) ...[
                          const SizedBox(width: 10),
                          Text(
                            selectedLanguage,
                            style: bodyLText.copyWith(color: blackColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Opacity(
                  opacity: paired != '' ? 1.0 : 0.0,
                  child: Text(
                    "Paired with $paired",
                    style: h3Text.copyWith(color: primaryColor100),
                  ),
                ),
                PopupMenuButton<int>(
                  icon: Icon(
                    Icons.account_circle_outlined,
                    color: whiteColor,
                    size: 60,
                  ),
                  onSelected: (value) {
                    if (value == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryPage(),
                        ),
                      );
                    } else if (value == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgetPasswordPage(),
                        ),
                      );
                    } else if (value == 2) {
                      _showLogoutDialog(context);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/history.png"),
                          const SizedBox(width: 10),
                          Text(
                            tr("history"),
                            style: bodyLText.copyWith(color: secondaryColor500),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/key.png"),
                          const SizedBox(width: 10),
                          Text(
                            tr("change_password"),
                            style: bodyLText.copyWith(color: secondaryColor500),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/logout.png"),
                          const SizedBox(width: 10),
                          Text(
                            tr("log_out"),
                            style: bodyLText.copyWith(color: errorColor500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: 84,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      text: "${tr("hello_user")}, ",
                      style: h1Text.copyWith(
                          color: whiteColor, fontWeight: medium),
                      children: [
                        TextSpan(
                          text: displayName,
                          style: h1Text.copyWith(
                              color: whiteColor, fontWeight: bold),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tr("ready_to_start"),
                    textAlign: TextAlign.center,
                    style: titleText.copyWith(color: whiteColor),
                  ),
                  const SizedBox(
                    height: 48,
                  ),
                  Center(
                      child: paired == ''
                          ? SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  // SizedBox(
                                  //   width: 380,
                                  //   child: ElevatedButton(
                                  //     onPressed: () {
                                  //       _showQRDialog(context);
                                  //     },
                                  //     style: ElevatedButton.styleFrom(
                                  //       padding: const EdgeInsets.symmetric(
                                  //           vertical: 16),
                                  //       backgroundColor: secondaryColor500,
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius:
                                  //             BorderRadius.circular(8),
                                  //       ),
                                  //     ),
                                  //     child: Text(
                                  //       "Show QR",
                                  //       style: bodyLText.copyWith(
                                  //         color: whiteColor,
                                  //         fontWeight: medium,
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                  // const SizedBox(
                                  //   height: 12,
                                  // ),
                                  SizedBox(
                                    width: 380,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const QrScannerPage()),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor: whiteColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Start Pairing",
                                        style: bodyLText.copyWith(
                                          color: secondaryColor500,
                                          fontWeight: medium,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 380,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        speechState.updateLastWords('');
                                        speechState.updateCurrentWords('');
                                        speechState.updateTranslatedText('');
                                        speechState.updateTempText('coba');
                                        speechState.updateSpeechEnabled(false);
                                        speechState.updateBeforeEdit(true);
                                        speechState.updateIsTyping(false);
                                        editableController.text = "";
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TranslatePage(
                                                editableController:
                                                    editableController,
                                                isToUid: pairedProvider.isToUid,
                                                key: UniqueKey()),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor: secondaryColor500,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Start Translate",
                                        style: bodyLText.copyWith(
                                          color: whiteColor,
                                          fontWeight: medium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width: 380,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const QrScannerPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor: whiteColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Pair with other device",
                                        style: bodyLText.copyWith(
                                          color: secondaryColor500,
                                          fontWeight: medium,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                ],
              ),
            ),
          ),
          if (isDropdownOpen)
            Positioned(
              top: 110,
              left: 100,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 252,
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: blackColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: languages.map((lang) {
                      bool isActive = lang["name"] == selectedLanguage;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedLanguage = lang["name"]!;
                            Locale locale = _getLocaleFromLang(lang["locale"]!);
                            context.setLocale(locale);
                            isDropdownOpen = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? Colors.grey[200] : null,
                            borderRadius:
                                lang["name"] == languages.first["name"]
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      )
                                    : lang["name"] == languages.last["name"]
                                        ? const BorderRadius.only(
                                            bottomLeft: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                          )
                                        : BorderRadius.circular(0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  lang["icon"]!,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  lang["name"]!,
                                  style: bodyLText.copyWith(color: blackColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

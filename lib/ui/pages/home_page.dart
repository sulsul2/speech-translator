import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/forget_password_page.dart';
import 'package:speech_translator/ui/pages/pair_devices_page.dart';
import 'package:speech_translator/ui/pages/translate_page.dart';
import 'package:speech_translator/ui/pages/welcome_page.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatefulWidget {
  final String paired;

  const HomePage({super.key, required this.paired});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  String selectedLanguage = "Bahasa Indonesia";

  final List<Map<String, String>> languages = [
    {"name": "Bahasa Indonesia", "icon": "assets/flag_ind.png", "locale": "id"},
    {"name": "English", "icon": "assets/flag_en.png", "locale": "en"},
    {"name": "日本語", "icon": "assets/flag_jap.png", "locale": "ja"},
    {"name": "廣東話", "icon": "assets/flag_hk.png", "locale": "zh_HK"},
  ];

  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      _firebaseService.listenForPairingRequests(currentUser.uid, context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setLanguageFromLocale();
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

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
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
            top: 60,
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
                  opacity: widget.paired != '' ? 1.0 : 0.0,
                  child: Text(
                    "Paired with ${widget.paired}",
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
                      // Handle History
                    } else if (value == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgetPasswordPage(),
                        ),
                      );
                    } else if (value == 2) {
                      _logout(context);
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
                    height: 72,
                  ),
                  Center(
                      child: widget.paired == ''
                          ? ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PairDevicesPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 140),
                                backgroundColor: whiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                tr("start_pairing"),
                                style: bodyLText.copyWith(
                                    color: secondaryColor500,
                                    fontWeight: medium),
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TranslatePage(),
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
                                                const PairDevicesPage(),
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
              top: 130,
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

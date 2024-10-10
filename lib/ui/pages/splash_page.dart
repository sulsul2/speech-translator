import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String selectedLanguage = 'Select Language';

  List<Map<String, dynamic>> languages = [
  {'label': '🇬🇧 English', 'locale': Locale('en')},
  {'label': '🇮🇩 Indonesian', 'locale': Locale('id')},
  {'label': '🇯🇵 Japanese', 'locale': Locale('ja')},
  {'label': '🇭🇰 Cantonese', 'locale': Locale('zh', 'HK')},
];

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Warning"),
          content: const Text("Please select a language before proceeding."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
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
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Translate \nEverything",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 64, color: whiteColor, fontWeight: bold),
                ),
                const SizedBox(
                  height: 40,
                ),
                Text(
                  "Choose language to start",
                  textAlign: TextAlign.center,
                  style: h1Text.copyWith(color: whiteColor),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          left: 16, right: 48, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: DropdownButton<String>(
                        value: selectedLanguage == 'Select Language'
                            ? null
                            : selectedLanguage,
                        icon: const SizedBox.shrink(),
                        dropdownColor: whiteColor,
                        hint: Row(
                          children: [
                            Icon(Icons.language,
                                color: grayColor300,
                                size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Select Language',
                              style: h3Text.copyWith(
                                  color: grayColor300, fontWeight: regular),
                            ),
                          ],
                        ),
                        style: h3Text.copyWith(
                            color: grayColor300, fontWeight: regular),
                        underline: const SizedBox(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLanguage = newValue!;
                          });
                        },
                        items: languages
                            .map<DropdownMenuItem<String>>((Map<String, dynamic> language) {
                          return DropdownMenuItem<String>(
                            value: language['label'],
                            child: Text(language['label']),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (selectedLanguage == 'Select Language') {
                          _showAlertDialog(context);
                        } else {
                          final selectedLocale = languages.firstWhere(
                              (language) => language['label'] == selectedLanguage)['locale'];
                          
                          context.setLocale(selectedLocale);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WelcomePage()),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryColor500,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ))
        ],
      ),
    );
  }
}

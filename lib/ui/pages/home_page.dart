import 'package:flutter/material.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/pair_devices_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          Positioned(
            top: 60,
            left: 100,
            right: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: whiteColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/flag_ind.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Icon(
                  Icons.account_circle_outlined,
                  color: whiteColor,
                  size: 60,
                )
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
                    text: "Hello, ",
                    style:
                        h1Text.copyWith(color: whiteColor, fontWeight: medium),
                    children: [
                      TextSpan(
                        text: "Nadya",
                        style: h1Text.copyWith(
                            color: whiteColor, fontWeight: bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Ready to start translating\nlive conversations with\nyour partner?",
                  textAlign: TextAlign.center,
                  style: titleText.copyWith(color: whiteColor),
                ),
                const SizedBox(
                  height: 72,
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PairDevicesPage()),
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
                      'Start Pairing',
                      style: bodyLText.copyWith(
                          color: secondaryColor500, fontWeight: medium),
                    ),
                  ),
                ),
              ],
            ),
          ))
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/sign_in_page.dart';
import 'package:speech_translator/ui/pages/sign_up_page.dart';
import 'package:speech_translator/ui/widgets/input_field.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController =
        TextEditingController(text: '');

    Widget socialButton({
      required String text,
      required String iconPath,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          side: BorderSide(color: grayColor200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              iconPath,
              height: 32,
              width: 32,
            ),
            Text(
              text,
              style: bodyLText.copyWith(color: blackColor, fontWeight: medium),
            ),
            Opacity(
              opacity: 0,
              child: Image.asset(
                iconPath,
                height: 32,
                width: 32,
              ),
            ),
          ],
        ),
      );
    }

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
            child: Container(
              color: secondaryColor700.withOpacity(0.5),
            ),
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 36),
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back_ios_new,
                                color: blackColor)),
                        Text(
                          "signInSignUp".tr(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: medium,
                              color: grayColor400),
                        ),
                        Opacity(
                          opacity: 0,
                          child:
                              Icon(Icons.arrow_back_ios_new, color: blackColor),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 32,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "welcome".tr(),
                          style: h1Text.copyWith(color: blackColor),
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        InputField(
                          textController: emailController,
                          hintText: "email_username_hint".tr(),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignInPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: primaryColor600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'continue'.tr(),
                              style: bodyLText.copyWith(
                                  color: whiteColor, fontWeight: medium),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: grayColor100,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'or'.tr(),
                                style: bodySText.copyWith(
                                  color: grayColor400,
                                  fontWeight: medium,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: grayColor100,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 48,
                        ),
                        socialButton(
                          text: "continue_with_google".tr(),
                          iconPath: 'assets/google.png',
                          onPressed: () {},
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        socialButton(
                          text: "continue_with_apple".tr(),
                          iconPath: 'assets/apple.png',
                          onPressed: () {},
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()),
                              );
                            },
                            child: Text(
                              "no_account".tr(),
                              style: bodySText.copyWith(
                                  color: primaryColor500,
                                  fontWeight: medium,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primaryColor500),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

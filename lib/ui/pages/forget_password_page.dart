import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/verification_code_page.dart';
import 'package:speech_translator/ui/widgets/input_field.dart';

class ForgetPasswordPage extends StatelessWidget {
  const ForgetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController =
        TextEditingController(text: '');
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
                          "sign_in".tr(),
                          style: bodyMText.copyWith(
                              fontWeight: medium, color: grayColor400),
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
                          "forget_password".tr(),
                          style: h1Text.copyWith(color: blackColor),
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        InputField(
                            textController: emailController,
                            hintText: "email".tr()),
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
                                    builder: (context) =>
                                        const VerificationCodePage()),
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

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/reset_password_page.dart';

class VerificationCodePage extends StatefulWidget {
  const VerificationCodePage({super.key});

  @override
  _VerificationCodePageState createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Widget buildOtpBox(int index) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextField(
        focusNode: _focusNodes[index],
        controller: _controllers[index],
        textAlign: TextAlign.center,
        style: h1Text.copyWith(color: blackColor),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor500, width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
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
                          "verification_code".tr(),
                          style: h1Text.copyWith(color: blackColor),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  style: bodyLText,
                                  children: [
                                    TextSpan(
                                      text: "${"otp_sent".tr()} ",
                                      style: TextStyle(color: grayColor300),
                                    ),
                                    TextSpan(
                                      text: "marchellinednadya@gmail.com",
                                      style: TextStyle(
                                          color: blackColor,
                                          fontWeight: medium),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return buildOtpBox(index);
                          }),
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ResetPasswordPage()),
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
                          height: 16,
                        ),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "didnt_get_code".tr(),
                              style: bodySText.copyWith(color: blackColor),
                              children: [
                                TextSpan(
                                  text: "resend_code".tr(),
                                  style: bodySText.copyWith(
                                      color: primaryColor500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: primaryColor500),
                                ),
                              ],
                            ),
                          ),
                        ),
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

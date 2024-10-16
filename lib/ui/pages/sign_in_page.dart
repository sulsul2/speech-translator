import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/forget_password_page.dart';
import 'package:speech_translator/ui/pages/home_page.dart';
import 'package:speech_translator/ui/widgets/input_field.dart';

class SignInPage extends StatefulWidget {
  final String email;
  const SignInPage({super.key, required this.email});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String? firebaseEmailError;
  String? firebasePasswordError;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
  }

  Future<void> _signIn(BuildContext context) async {
    setState(() {
      firebaseEmailError = null;
      firebasePasswordError = null;
    });

    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            firebaseEmailError = 'No user found for that email';
          } else if (e.code == 'wrong-password') {
            firebasePasswordError = 'Wrong password provided for that user';
          } else {
            firebaseEmailError = '${e.message}';
          }
        });

        _formKey.currentState!.validate();
      }
    }
  }

  String? emailValidator(String? value) {
    if (firebaseEmailError != null) return firebaseEmailError;
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (firebasePasswordError != null) return firebasePasswordError;
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
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
              child: Form(
                key: _formKey,
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
                            child: Icon(Icons.arrow_back_ios_new,
                                color: blackColor),
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
                            "enter_password".tr(),
                            style: h1Text.copyWith(color: blackColor),
                          ),
                          const SizedBox(
                            height: 28,
                          ),
                          InputField(
                            textController: emailController,
                            hintText: "email".tr(),
                            validator: emailValidator,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          InputField(
                            textController: passwordController,
                            hintText: "password".tr(),
                            isPassword: true,
                            validator: passwordValidator,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _signIn(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: primaryColor600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'sign_in'.tr(),
                                style: bodyLText.copyWith(
                                    color: whiteColor, fontWeight: medium),
                              ),
                            ),
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
                                      builder: (context) =>
                                          const ForgetPasswordPage()),
                                );
                              },
                              child: Text(
                                "forget_password?".tr(),
                                style: bodySText.copyWith(
                                    color: blackColor,
                                    fontWeight: medium,
                                    decoration: TextDecoration.underline,
                                    decorationColor: blackColor),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

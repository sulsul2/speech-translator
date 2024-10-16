import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/email_verification_page.dart';
import 'package:speech_translator/ui/widgets/input_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePasswordPage extends StatefulWidget {
  final String email;
  final String username;
  const CreatePasswordPage({super.key, required this.email, required this.username});

  @override
  _CreatePasswordPageState createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _registerAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: widget.email,
          password: passwordController.text,
        );

        await userCredential.user!.updateDisplayName(widget.username);
        await userCredential.user!.sendEmailVerification();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'email-already-in-use') {
          errorMessage = 'The email address is already in use by another account.';
        } else {
          errorMessage = 'Failed to register: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                            "sign_up".tr(),
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
                            "create_secure_password".tr(),
                            style: h1Text.copyWith(color: blackColor),
                          ),
                          const SizedBox(
                            height: 28,
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
                          InputField(
                            textController: passwordConfirmController,
                            hintText: "confirm_password".tr(),
                            isPassword: true,
                            validator: confirmPasswordValidator,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registerAccount,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: primaryColor600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'sign_up'.tr(),
                                      style: bodyLText.copyWith(
                                          color: whiteColor, fontWeight: medium),
                                    ),
                            ),
                          ),
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

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_translator/ui/pages/home_page.dart';
import 'package:speech_translator/ui/pages/sign_in_page.dart';
import 'package:speech_translator/ui/pages/sign_up_page.dart';
import 'package:speech_translator/ui/widgets/input_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});

  final FirebaseService _firebaseService = FirebaseService();

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        await _firebaseService.saveUserData(
          user.uid,
          user.displayName ?? googleUser.displayName ?? 'Anonymous', 
          user.email ?? googleUser.email,
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  Future<User?> signInWithApple(BuildContext context) async {
    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.identityToken == null) {
        print('Error: Missing identity token');
        return null;
      }

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        await _firebaseService.saveUserData(
          user.uid,
          user.displayName ?? 'Anonymous', 
          user.email ?? 'email@anonymous.com',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }

      return user;
    } catch (e) {
      print('Error during Apple Sign-In: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController =
        TextEditingController(text: '');
    final formKey = GlobalKey<FormState>();

    String? emailValidator(String? value) {
      if (value == null || value.isEmpty) {
        return 'email_username_empty'.tr();
      }
      String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      RegExp regex = RegExp(pattern);
      if (!regex.hasMatch(value)) {
        return 'email_invalid'.tr();
      }
      return null;
    }

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
      resizeToAvoidBottomInset: true,
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    constraints: const BoxConstraints(maxWidth: 600),
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
                                "welcome".tr(),
                                style: h1Text.copyWith(color: blackColor),
                              ),
                              const SizedBox(
                                height: 28,
                              ),
                              Focus(
                                onFocusChange: (hasFocus) {
                                  if (hasFocus) {
                                    Scrollable.ensureVisible(
                                      context,
                                      alignment: 0.5,
                                      duration:
                                          const Duration(milliseconds: 300),
                                    );
                                  }
                                },
                                child: InputField(
                                  textController: emailController,
                                  hintText: "email_username_hint".tr(),
                                  validator: emailValidator,
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SignInPage(
                                            email: emailController.text,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
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
                                onPressed: () async {
                                  User? user = await signInWithGoogle(context);
                                  if (user != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const HomePage()),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              socialButton(
                                text: "continue_with_apple".tr(),
                                iconPath: 'assets/apple.png',
                                onPressed: () async {
                                  await signInWithApple(context);
                                },
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
                                              const SignUpPage()),
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
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

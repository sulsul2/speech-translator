import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:speech_translator/ui/pages/home_page.dart';
import 'package:speech_translator/ui/pages/splash_page.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  await EasyLocalization.ensureInitialized();

  // Meminta izin mikrofon sebelum menjalankan aplikasi
  await requestMicrophonePermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => PairedProvider()), // Tambahkan Provider disini
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('id'),
          Locale('ja'),
          Locale('zh', 'HK'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    ),
  );
}

// Fungsi untuk meminta izin mikrofon
Future<void> requestMicrophonePermission() async {
  var status = await Permission.microphone.status;
  print(status);
  await Permission.microphone.request();
  print(status);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: FirebaseAuth.instance.currentUser == null
          ? const SplashPage()
          : const HomePage(),
    );
  }
}

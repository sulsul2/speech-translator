import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  bool _switch = false;
  final SpeechToText _speech = SpeechToText();
  String _text = '';
  String _translatedText = '';
  final translator = GoogleTranslator();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speech.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _text = result.recognizedWords;
    });
    _translateText();
  }

  void _translateText() async {
    if (_text.isNotEmpty) {
      try {
        var translation =
            await translator.translate(_text, from: 'id', to: 'en');
        setState(() {
          _translatedText = translation.text;
        });
      } catch (e) {
        setState(() {
          _translatedText = 'Error occurred during translation';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget header() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
        color: primaryColor500,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: whiteColor,
              ),
            ),
            Row(
              children: [
                Image.asset('assets/bluetooth_icon.png'),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  "Paired with Christine’s Ipad 11",
                  style: h4Text.copyWith(color: whiteColor),
                ),
              ],
            ),
            Image.asset(
              'assets/audio_line_icon.png',
              height: 32,
            )
          ],
        ),
      );
    }

    Widget mainContent() {
      return Container(
        margin: const EdgeInsets.only(top: 90),
        decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40), topRight: Radius.circular(40))),
        child: Column(
          children: [
            SizedBox(
              height: 500,
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 36),
                    color: primaryColor50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/audio_icon.png'),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Bahasa Indonesia",
                                  style:
                                      h4Text.copyWith(color: secondaryColor500),
                                )
                              ],
                            ),
                            Visibility(
                                visible:
                                    _text.isNotEmpty && _speech.isNotListening,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _text = '';
                                      _translatedText = '';
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: secondaryColor300,
                                    size: 28,
                                  ),
                                ))
                          ],
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        SizedBox(
                          height: 340,
                          child: Text(
                            _text.isEmpty && _speech.isNotListening
                                ? "Tekan tombol mikrofon untuk memulai"
                                : _speech.isListening && _text.isEmpty
                                    ? "Mendengarkan..."
                                    : _text,
                            style: h2Text.copyWith(color: secondaryColor200),
                          ),
                        ),
                        Expanded(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _text.length.toString(),
                              style: h4Text.copyWith(color: secondaryColor500),
                            )
                          ],
                        ))
                      ],
                    ),
                  )),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 36),
                    color: whiteColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/audio_icon.png'),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Bahasa Indonesia",
                              style: h4Text.copyWith(color: secondaryColor500),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        Container(
                          color: whiteColor,
                          width: double.infinity,
                          height: 340,
                          child: Text(
                            _translatedText.isEmpty && _speech.isNotListening
                                ? "Tekan tombol mikrofon untuk memulai"
                                : _speech.isListening && _translatedText.isEmpty
                                    ? "Listening..."
                                    : _translatedText,
                            style: h2Text.copyWith(color: secondaryColor200),
                          ),
                        ),
                        Expanded(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _translatedText.length.toString(),
                              style: h4Text.copyWith(color: secondaryColor500),
                            )
                          ],
                        ))
                      ],
                    ),
                  ))
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: whiteColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.history,
                            color: secondaryColor200,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _speech.isNotListening
                          ? _startListening
                          : _stopListening,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 52),
                        padding: EdgeInsets.symmetric(
                          horizontal: _speech.isListening ? 22 : 25,
                          vertical: _speech.isListening ? 22 : 17,
                        ),
                        decoration: BoxDecoration(
                          color: _speech.isListening
                              ? errorColor500
                              : (_speechEnabled
                                  ? primaryColor500
                                  : Colors.grey),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: _speech.isListening
                            ? Icon(
                                Icons.stop,
                                color: whiteColor,
                                size: 50,
                              )
                            : Image.asset('assets/mic_icon.png'),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CupertinoSwitch(
                              trackColor: secondaryColor100,
                              activeColor: secondaryColor500,
                              value: _switch,
                              onChanged: (bool value) {
                                setState(() {
                                  _switch = value;
                                });
                              }),
                          const SizedBox(
                            width: 12,
                          ),
                          Text(
                            "Live",
                            style: h4Text.copyWith(color: secondaryColor200),
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

    return Scaffold(
      backgroundColor: primaryColor500,
      body: SafeArea(
        child: Stack(
          children: [header(), mainContent()],
        ),
      ),
    );
  }
}

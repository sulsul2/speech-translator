import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_translator/models/history_model.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

class TranslatePage extends StatefulWidget {
  final bool isToUid;
  const TranslatePage({super.key, required this.isToUid});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  bool _switch = false;
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _speechAvailable = false;
  String _lastWords = '';
  String _currentWords = '';
  String _translatedText = '';
  final translator = GoogleTranslator();
  String _selectedLanguage = 'Bahasa Indonesia';
  TextEditingController searchController = TextEditingController();
  String _searchText = '';
  String? idPair = '';
  List<History> _currentData = [];

  List<String> filteredLanguages = [];
  List<History> historyList = [];

  void fetchDataFromFirebase() async {
    FirebaseService firebaseService = FirebaseService();
    List<History> fetchedHistory =
        await firebaseService.fetchTranslationHistory();

    User? user = FirebaseAuth.instance.currentUser;
    idPair = await firebaseService.getIdPair(user!.uid, widget.isToUid);

    setState(() {
      historyList = fetchedHistory;
    });
  }

  Map<String, History> realtimeTranslations = {};
  StreamSubscription<DatabaseEvent>? _translationSubscription;

  @override
  void initState() {
    super.initState();
    _filteredLanguages();
    _initSpeech();
    fetchDataFromFirebase();
    _setupRealtimeTranslations();
  }

  @override
  void dispose() {
    _translationSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeTranslations() {
    final DatabaseReference historyRef =
        FirebaseDatabase.instance.ref().child('history');

    historyRef.get().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map &&
              value['idPair'] == idPair &&
              value['pairedBluetooth'] == 'sulsul') {
            setState(() {
              realtimeTranslations[key] = History.fromJson(value);
            });
          }
        });
      }
    });

    // Listen untuk perubahan baru
    _translationSubscription =
        historyRef.onChildAdded.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final key = event.snapshot.key ?? '';

        if (data['idPair'] == idPair &&
            data['pairedBluetooth'] == 'sulsul' &&
            !realtimeTranslations.containsKey(key)) {
          setState(() {
            realtimeTranslations[key] = History.fromJson(data);
          });
        }

        User? user = FirebaseAuth.instance.currentUser;
        String username = user?.displayName ?? '';
        if (data['username'] == username) {
          setState(() {
            historyList.add(History.fromJson(data));
          });
        }
      }
    });
  }

  void _filteredLanguages() {
    setState(() {
      filteredLanguages = languageCodes.keys
          .where(
              (lang) => lang.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    });
  }

  void errorListener(SpeechRecognitionError error) async {
    debugPrint(error.errorMsg.toString());
    if (!_switch) {
      _stopListening();
    }
  }

  void statusListener(String status) async {
    debugPrint("status $status");
    if (_switch) {
      if (status == "done" && _speechEnabled) {
        if (_currentWords.isNotEmpty) {
          setState(() {
            _lastWords += " $_currentWords";
            _currentWords = "";
            _speechEnabled = false;
          });
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await _startListening();
        await _translateText();
      }
    } else {
      if (_currentWords.isNotEmpty) {
        setState(() {
          _lastWords = " $_currentWords";
          _currentWords = "";
          _speechEnabled = false;
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await _translateText();
    }
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
        onError: errorListener, onStatus: statusListener);
    setState(() {});
  }

  _startListening() async {
    await _stopListening();
    await Future.delayed(const Duration(milliseconds: 50));
    await _speech.listen(
        onResult: _onSpeechResult,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 10));
    setState(() {
      if (_switch) {
        _speechEnabled = true;
      }
    });
  }

  _stopListening() async {
    setState(() {
      _speechEnabled = false;
    });
    await _speech.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _currentWords = result.recognizedWords;
    });
  }

  Future _translateText() async {
    if (_lastWords.isNotEmpty) {
      try {
        String targetLanguageCode = languageCodes[_selectedLanguage] ?? 'en';

        var translation = await translator.translate(_lastWords,
            from: 'id', to: targetLanguageCode);

        setState(() {
          _translatedText = translation.text;
        });

        _currentData.add(History(
            realWord: _lastWords,
            translatedWord: _translatedText,
            firstLang: '-',
            secondLang: '-'));

        if (_currentData.length > 1) {
          User? user = FirebaseAuth.instance.currentUser;
          String displayName = user?.displayName ?? "User";
          FirebaseService firebaseService = FirebaseService();
          await firebaseService.saveTranslationHistory(
            "77",
            displayName,
            'komeng',
            'Bahasa Indonesia',
            _selectedLanguage,
            _currentData.last.realWord,
            _currentData.last.translatedWord,
          );

          print("Translation history saved successfully.");
        }
      } catch (e) {
        print("Translation error: $e");
        if (mounted) {
          setState(() {
            _translatedText = 'Error occurred during translation';
          });
        }
      }
    }
  }

  void _showLanguageSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: whiteColor,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                        hintText: 'Search languages',
                        hintStyle: bodyMText.copyWith(
                          color: secondaryColor300,
                          fontWeight: semibold,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/search_icon.png',
                            color: secondaryColor300,
                            width: 24,
                            height: 24,
                          ),
                        ),
                        border: InputBorder.none),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                        _filteredLanguages();
                      });
                    },
                  ),
                ),
                // const SizedBox(height: 20),
                const Divider(),
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredLanguages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 6,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = filteredLanguages[index];
                          });
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 32),
                          child: Text(
                            filteredLanguages[index],
                            style: bodyMText.copyWith(
                                color: secondaryColor500, fontWeight: semibold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    Widget historySection() {
      return historyList.isEmpty
          ? const Center(
              child: Text(
                'No history available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final historyItem = historyList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 56.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: grayColor25,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historyItem.realWord,
                          style: bodyMText.copyWith(color: secondaryColor300),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          historyItem.translatedWord,
                          style: h2Text.copyWith(
                              color: secondaryColor500, fontWeight: medium),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${historyItem.firstLang} → ${historyItem.secondLang}',
                          style: bodySText.copyWith(color: secondaryColor300),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
    }

    Widget _buildOriginalTextSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lastWords.isEmpty && _speech.isNotListening
                ? "Tekan tombol mikrofon untuk memulai"
                : _speech.isListening && _lastWords.isEmpty
                    ? "Mendengarkan..."
                    : 'Me: $_lastWords $_currentWords',
            style: h2Text.copyWith(color: secondaryColor200),
          ),
          if (realtimeTranslations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...realtimeTranslations.values
                .toList()
                .reversed
                .map((translation) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Komeng: ${translation.translatedWord}',
                          style: h2Text.copyWith(color: secondaryColor200),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ))
                .toList(),
          ],
        ],
      );
    }

    Widget _buildTranslatedTextSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translatedText.isEmpty && _speech.isNotListening
                ? "Tekan tombol mikrofon untuk memulai"
                : _speech.isListening && _translatedText.isEmpty
                    ? "Listening..."
                    : 'Me: $_translatedText',
            style: h2Text.copyWith(color: secondaryColor200),
          ),
          if (realtimeTranslations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...realtimeTranslations.values
                .toList()
                .reversed
                .map((translation) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Komeng: ${translation.realWord}',
                          style: h2Text.copyWith(color: secondaryColor200),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ))
                .toList(),
          ],
        ],
      );
    }

    Widget mainContent() {
      return Container(
        margin: const EdgeInsets.only(top: 90),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 36),
                            decoration: BoxDecoration(
                              color: primaryColor50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(40),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset('assets/audio_icon.png'),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Bahasa Indonesia",
                                          style: h4Text.copyWith(
                                              color: secondaryColor500),
                                        ),
                                      ],
                                    ),
                                    Visibility(
                                      visible: _lastWords.isNotEmpty &&
                                          _speech.isNotListening,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _lastWords = '';
                                            _currentWords = '';
                                            _translatedText = '';
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: secondaryColor300,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                Container(
                                  color: primaryColor50,
                                  width: double.infinity,
                                  height: 340,
                                  child: SingleChildScrollView(
                                    // Add ScrollView to handle multiple messages
                                    child: _buildOriginalTextSection(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _lastWords.length.toString(),
                                  style:
                                      h4Text.copyWith(color: secondaryColor500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 36),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(40),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.asset('assets/audio_icon.png'),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showLanguageSelection,
                                      child: Row(
                                        children: [
                                          Text(
                                            _selectedLanguage,
                                            style: h4Text.copyWith(
                                                color: secondaryColor500),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 24,
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                Container(
                                  color: whiteColor,
                                  width: double.infinity,
                                  height: 340,
                                  child: SingleChildScrollView(
                                    // Add ScrollView to handle multiple messages
                                    child: _buildTranslatedTextSection(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _translatedText.length.toString(),
                                  style:
                                      h4Text.copyWith(color: secondaryColor500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      color: whiteColor,
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 56.0, vertical: 39),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "History",
                                style: h2Text.copyWith(color: blackColor),
                              ),
                            ),
                          ),
                          historySection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
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
                    onTap: () {
                      if (_speech.isNotListening) {
                        setState(() {
                          _lastWords = "";
                          _translatedText = "";
                          _currentWords = "";
                        });
                        _startListening();
                      } else {
                        _stopListening();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 52),
                      padding: EdgeInsets.symmetric(
                        horizontal: _speech.isListening ? 22 : 25,
                        vertical: _speech.isListening ? 22 : 17,
                      ),
                      decoration: BoxDecoration(
                        color: _speech.isListening
                            ? errorColor500
                            : (_speechAvailable && _speech.isNotListening
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
                        const SizedBox(width: 12),
                        Text(
                          "Live",
                          style: h4Text.copyWith(color: secondaryColor200),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

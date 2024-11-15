import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_translator/models/history_model.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_translator/ui/pages/history_page.dart';
import 'package:translator/translator.dart';

class TranslatePage extends StatefulWidget {
  final bool isToUid;
  const TranslatePage({super.key, required this.isToUid});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

bool isTyping = false;
bool _isTranslating = false;
bool _isDisposed = false; // Tambahkan flag untuk melacak status dispose
bool _switch = false;
final translator = GoogleTranslator();
String _currentWords = '';
bool _speechEnabled = false;
bool _speechAvailable = false;
String _lastWords = '';
String _translatedText = '';
String _selectedLanguage = 'Bahasa Indonesia';
String _selectedFromLanguage = 'English';
String temp = '';
bool _beforeEdit = true;

class _TranslatePageState extends State<TranslatePage> {
  final SpeechToText _speech = SpeechToText();
  TextEditingController searchController = TextEditingController();
  TextEditingController _editableController = TextEditingController();
  String _searchText = '';
  String? idPair = '';
  List<History> _currentData = [];
  String pairedBluetooth = '';
  String _currentUser = '';
  Timer? _debounce;

  List<String> filteredLanguages = [];
  List<History> historyList = [];

  void fetchDataFromFirebase() async {
    FirebaseService firebaseService = FirebaseService();

    User? user = FirebaseAuth.instance.currentUser;
    if (!_isDisposed) {
      setState(() {
        _currentUser = user?.displayName ?? '';
      });
    }

    Map<String, String?>? pairingInfo =
        await firebaseService.getIdPair(user!.uid, widget.isToUid);

    if (pairingInfo != null) {
      String? pairUid = pairingInfo['pairUid'];
      if (pairUid != null) {
        String? username = await firebaseService.getUsernameFromUid(pairUid);
        print(username);
        if (username != null) {
          if (!_isDisposed) {
            setState(() {
              idPair = pairingInfo['idPair'];
              pairedBluetooth = username;
            });
          }
        }
      }
    }

    if (!_isDisposed) {
      List<History> fetchedHistory = await firebaseService
          .fetchPairedTranslationHistory(pairedBluetooth, idPair);

      setState(() {
        historyList = fetchedHistory;
      });
    }
  }

  Map<String, History> realtimeTranslations = {};
  StreamSubscription<DatabaseEvent>? _translationSubscription;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _lastWords = "";
    _currentWords = "";
    _translatedText = "";
    _filteredLanguages();
    _initSpeech();
    fetchDataFromFirebase();
    _setupRealtimeTranslations();
    temp = "coba";
  }

  @override
  void dispose() {
    super.dispose();
    _isDisposed = true; // Tandai widget sebagai telah dihancurkan

    _translationSubscription?.cancel();
    _stopListening(); // Pastikan sesi mendengarkan dihentikan
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSpeech();
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
              value['pairedBluetooth'] == _currentUser) {
            if (!_isDisposed) {
              setState(() {
                realtimeTranslations[key] = History.fromJson(value);
              });
            }
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
            data['pairedBluetooth'] == _currentUser &&
            !realtimeTranslations.containsKey(key)) {
          if (!_isDisposed) {
            setState(() {
              realtimeTranslations[key] = History.fromJson(data);

              _currentData.add(History.fromJson(data));
            });
          }
        }

        User? user = FirebaseAuth.instance.currentUser;
        String username = user?.displayName ?? '';
        if (data['username'] == username) {
          if (!_isDisposed) {
            setState(() {
              historyList.add(History.fromJson(data));
            });
          }
        }
      }
    });
  }

  void _filteredLanguages() {
    if (!_isDisposed) {
      setState(() {
        filteredLanguages = languageCodes.keys
            .where((lang) =>
                lang.toLowerCase().contains(_searchText.toLowerCase()))
            .toList();
      });
    }
  }

  void errorListener(SpeechRecognitionError error) async {
    print("APAKAH ERROR");
    if (!_isDisposed) {
      debugPrint(error.errorMsg.toString());
      if (!_switch) {
        await _stopListening();
      }
    }
  }

  void statusListener(String status) async {
    print("MLEBU RA");
    print(_isDisposed);
    if (!_isDisposed) {
      debugPrint("status $status");
      print(_currentWords);
      if (_switch && status == "done" && _speechEnabled) {
        if (_currentWords.isNotEmpty) {
          _lastWords = " $_currentWords";
          _currentWords = "";
          _speechEnabled = false;
        }
        await Future.delayed(const Duration(milliseconds: 50));
        await _startListening();
        await _translateText();
      } else if (!_switch && _currentWords.isNotEmpty) {
        if (!_isDisposed) {
          print("FAKK");
          print(_currentWords);
          _lastWords = " $_currentWords";
          _currentWords = "";
          _speechEnabled = false;
          print("FAKK 2");
          print(_currentWords);
        }
        await _translateText();
        await _stopListening();
      } else {
        print("TT");
      }
    } else {
      print("JMBUTT");
    }
  }

  void _initSpeech() async {
    if (!_isDisposed) {
      print("MASUK IS DISPOSED");
      try {
        _speechAvailable = await _speech.initialize(
          onError: errorListener,
          onStatus: statusListener,
        );
        print(_speechAvailable);
        if (!_isDisposed) {
          setState(() {});
        }
      } catch (e) {
        print("Error during _initSpeech: $e");
      }
    } else {
      print("PPPPPPP");
    }
  }

  Future<void> _startListening() async {
    print("START");
    if (_speech.isNotListening && _speechAvailable) {
      print("AVAILABLE");
      print(languageCodes[_selectedLanguage]);
      try {
        await _speech.listen(
          localeId: languageCodes[_selectedFromLanguage],
          onResult: _onSpeechResult,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 10),
        );
        setState(() {
          _speechEnabled = true;
        });
      } catch (e) {
        print("Error during _startListening: $e");
      }
    } else {
      print("RA LISTEN");
    }
  }

  Future<void> _stopListening() async {
    if (!_isDisposed) {
      setState(() {
        _speechEnabled = false;
        if (!_switch) {
          _beforeEdit = false;
        }
      });
    }
    await _speech.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print("MLEBU ON SPEECH");
    if (!_isDisposed) {
      _currentWords = result.recognizedWords;
      print(_currentWords);
    }
  }

  Future _translateText() async {
    print("TRENSLET");
    if (_lastWords.isNotEmpty) {
      try {
        String targetLanguageCode = languageCodes[_selectedLanguage] ?? 'en';
        String fromLanguageCode = languageCodes[_selectedFromLanguage] ?? 'en';

        var translation = await translator.translate(_lastWords,
            from: fromLanguageCode, to: targetLanguageCode);
        setState(() {
          _translatedText = translation.text;
        });

        // _currentData.add(History(
        //     realWord: _lastWords,
        //     translatedWord: _translatedText,
        //     firstLang: '-',
        //     secondLang: '-'));

        print("KONTOL");
        if (_lastWords.length > 1 && _lastWords != temp && _switch) {
          User? user = FirebaseAuth.instance.currentUser;
          String displayName = user?.displayName ?? "User";
          FirebaseService firebaseService = FirebaseService();
          await firebaseService.saveTranslationHistory(
            idPair ?? '',
            displayName,
            pairedBluetooth,
            _selectedFromLanguage,
            _selectedLanguage,
            _lastWords,
            _translatedText,
          );
          temp = _lastWords;
          print("Translation history saved successfully.");
        }
      } catch (e) {
        print("Translation error: $e");
        if (mounted) {
          _translatedText = 'Error occurred during translation';
        }
      } finally {
        _isTranslating = false; // Reset flag after completion
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

  void _showFromLanguageSelection() {
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
                            _selectedFromLanguage = filteredLanguages[index];
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
    final paired = context.watch<PairedProvider>().pairedDevice;
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
                Text(
                  "Paired with $paired",
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
      if (!_beforeEdit) {
        _editableController.text = _lastWords;
      }
      if (_switch) {
        _editableController.text = _lastWords;
      }
      print("MASOOOKKK");
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_lastWords
                  .isNotEmpty) // Show "Me" text only if _lastWords is not empty
                Text(
                  "Me: ",
                  style: h2Text.copyWith(color: secondaryColor200),
                ),
              Expanded(
                child: TextField(
                  controller: _editableController,
                  // enabled: _beforeEdit ? false : true,
                  onChanged: (newText) {
                    isTyping = true; // Tandai sedang mengetik
                    if (_debounce?.isActive ?? false) _debounce!.cancel();

                    _debounce =
                        Timer(const Duration(milliseconds: 500), () async {
                      isTyping =
                          false; // Tandai selesai mengetik setelah 500 ms tanpa input baru
                      setState(() {
                        _lastWords = newText;
                      });
                      if (!isTyping) {
                        await _translateText(); // Panggil terjemahan setelah mengetik selesai
                      }
                      if (newText.isEmpty) {
                        _translatedText = '';
                      }
                    });
                  },
                  decoration: InputDecoration(
                    enabled: _beforeEdit ? false : true,
                    hintStyle: h2Text.copyWith(color: secondaryColor200),
                    hintText: _lastWords.isEmpty && !_speechEnabled
                        ? "Tekan tombol mikrofon untuk memulai"
                        : _speechEnabled && _lastWords.isEmpty
                            ? "Mendengarkan..."
                            : null,
                    border: InputBorder.none, // Remove border
                  ),
                  style: h2Text.copyWith(color: secondaryColor200),
                  maxLines: null, // Allow multiline editing if needed
                ),
              ),
            ],
          ),
          if (realtimeTranslations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '$pairedBluetooth: ${_currentData.last.translatedWord}',
              style: h2Text.copyWith(color: secondaryColor200),
            ),
          ],
        ],
      );
    }

    Widget _buildTranslatedTextSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translatedText.isEmpty && !_speechEnabled
                ? "Tekan tombol mikrofon untuk memulai"
                : _speechEnabled && _translatedText.isEmpty
                    ? "Listening..."
                    : 'Me: $_translatedText',
            style: h2Text.copyWith(color: secondaryColor200),
          ),
          if (realtimeTranslations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '$pairedBluetooth: ${_currentData.last.realWord}',
              style: h2Text.copyWith(color: secondaryColor200),
            ),
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
                                  children: [
                                    Image.asset('assets/audio_icon.png'),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showFromLanguageSelection,
                                      child: Row(
                                        children: [
                                          Text(
                                            _selectedFromLanguage,
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
                                  color: primaryColor50,
                                  width: double.infinity,
                                  height: 340,
                                  child: SingleChildScrollView(
                                    child: _buildOriginalTextSection(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _editableController.text.length
                                          .toString(),
                                      style: h4Text.copyWith(
                                          color: secondaryColor500),
                                    ),
                                  ],
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _translatedText.length.toString(),
                                      style: h4Text.copyWith(
                                          color: secondaryColor500),
                                    ),
                                  ],
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryPage(),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.history,
                            color: secondaryColor200,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_speech.isNotListening) {
                        _lastWords = "";
                        _translatedText = "";
                        _editableController.text = "";
                        _currentWords = "";
                        _beforeEdit = true;
                        await _startListening();
                      } else {
                        if (_switch) {}
                        _stopListening();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 52),
                      padding: EdgeInsets.symmetric(
                        horizontal: _speechEnabled ? 22 : 25,
                        vertical: _speechEnabled ? 22 : 17,
                      ),
                      decoration: BoxDecoration(
                        color: _speechEnabled
                            ? errorColor500
                            : (_speechAvailable && _speech.isNotListening
                                ? primaryColor500
                                : Colors.grey),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: _speechEnabled
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
                      children: _switch
                          ? _speechEnabled
                              ? [const SizedBox()]
                              : [
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
                                    style: h4Text.copyWith(
                                        color: secondaryColor200),
                                  ),
                                ]
                          : !_speechEnabled && _beforeEdit
                              ? [
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
                                    style: h4Text.copyWith(
                                        color: secondaryColor200),
                                  ),
                                ]
                              : [
                                  GestureDetector(
                                    onTap: () async {
                                      if (!_speechEnabled) {
                                        User? user =
                                            FirebaseAuth.instance.currentUser;
                                        String displayName =
                                            user?.displayName ?? "User";
                                        FirebaseService firebaseService =
                                            FirebaseService();
                                        await firebaseService
                                            .saveTranslationHistory(
                                          idPair ?? '',
                                          displayName,
                                          pairedBluetooth,
                                          _selectedFromLanguage,
                                          _selectedLanguage,
                                          _lastWords,
                                          _translatedText,
                                        );
                                        setState(() {
                                          _beforeEdit = true;
                                        });
                                        print("_speechEnabled");
                                        print(_speechEnabled);
                                        print("_speechEnabled");
                                      }
                                    },
                                    child: Icon(
                                      Icons.send,
                                      color: _speechEnabled
                                          ? secondaryColor200
                                          : secondaryColor500,
                                    ),
                                  )
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

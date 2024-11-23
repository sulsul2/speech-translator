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
import 'package:speech_translator/providers/speech_provider.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_translator/ui/pages/pair_history_page.dart';
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
GoogleTranslator translator = GoogleTranslator();
bool _speechAvailable = false;
String _selectedLanguage = 'Bahasa Indonesia';
String _selectedFromLanguage = 'English';
String temp = '';

class _TranslatePageState extends State<TranslatePage> {
  late SpeechState speechState;
  TextEditingController _editableController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  TextEditingController searchController = TextEditingController();
  String _searchText = '';
  String? idPair = '';
  List<History> _currentData = [];
  String pairedBluetooth = '';
  String _currentUser = '';
  Timer? _debounce;

  List<String> filteredLanguages = [];
  List<History> historyList = [];
  Map<String, History> realtimeTranslations = {};
  StreamSubscription<DatabaseEvent>? _translationSubscription;

  void fetchDataFromFirebase() async {
    FirebaseService firebaseService = FirebaseService();

    User? user = FirebaseAuth.instance.currentUser;
    if (!_isDisposed) {
      if (mounted) {
        setState(() {
          _currentUser = user?.displayName ?? '';
        });
      }
    }

    Map<String, String?>? pairingInfo =
        await firebaseService.getIdPair(user!.uid, widget.isToUid);

    if (pairingInfo != null) {
      String? pairUid = pairingInfo['pairUid'];
      if (pairUid != null) {
        String? username = await firebaseService.getUsernameFromUid(pairUid);
        if (username != null) {
          if (!_isDisposed) {
            if (mounted) {
              setState(() {
                idPair = pairingInfo['idPair'];
                pairedBluetooth = username;
              });
            }
          }
        }
      }
    }

    if (!_isDisposed) {
      List<History> fetchedHistory =
          await firebaseService.fetchPairedTranslationHistory(idPair);
      if (mounted) {
        setState(() {
          historyList = fetchedHistory;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _editableController = TextEditingController();
    _editableController.addListener(() async {
      final newText = _editableController.text;

      if (newText.isNotEmpty && newText != temp) {
        await _translateText(); // Panggil fungsi translate
        temp = newText; // Perbarui teks terakhir untuk validasi
      } else if (newText.isEmpty) {
        speechState.updateTranslatedText(
            ''); // Kosongkan hasil terjemahan jika teks kosong
      }
    });
    getInit();
  }

  getInit() {
    _initSpeech();
    _isDisposed = false;

    _filteredLanguages();
    fetchDataFromFirebase();
    _setupRealtimeTranslations();
    temp = "coba";
    isTyping = false;
    _isTranslating = false;
    _isDisposed = false; // Tambahkan flag untuk melacak status dispose
    translator = GoogleTranslator();

    // _speechEnabled = false;
    _speechAvailable = false;
    // _lastWords = '';
    // _translatedText = '';
    _selectedLanguage = 'Bahasa Indonesia';
    _selectedFromLanguage = 'English';
    // _beforeEdit = true;
  }

  @override
  void dispose() {
    super.dispose();
    _debounce?.cancel();
    _editableController.removeListener(() {});
    _isDisposed = true; // Tandai widget sebagai telah dihancurkan
    _editableController.dispose();
    _translationSubscription?.cancel();
    _stopListening(); // Pastikan sesi mendengarkan dihentikan
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    speechState = Provider.of<SpeechState>(context, listen: false);
    getInit();
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
              if (mounted) {
                setState(() {
                  realtimeTranslations[key] = History.fromJson(value);
                });
              }
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
            if (mounted) {
              setState(() {
                realtimeTranslations[key] = History.fromJson(data);

                _currentData.add(History.fromJson(data));
              });
            }
          }
        }

        User? user = FirebaseAuth.instance.currentUser;
        String username = user?.displayName ?? '';
        if (data['username'] == username) {
          if (!_isDisposed) {
            if (mounted) {
              setState(() {
                historyList.add(History.fromJson(data));
              });
            }
          }
        } else if (data['pairedBluetooth'] == username) {
          if (!_isDisposed) {
            if (mounted) {
              setState(() {
                historyList.add(History.fromJson(data));
              });
            }
          }
        }
      }
    });
  }

  void _filteredLanguages() {
    if (!_isDisposed) {
      if (mounted) {
        setState(() {
          filteredLanguages = languageCodes.keys
              .where((lang) =>
                  lang.toLowerCase().contains(_searchText.toLowerCase()))
              .toList();
        });
      }
    }
  }

  void errorListener(SpeechRecognitionError error) async {
    if (!_isDisposed) {
      // debugPrint(error.errorMsg.toString());
      if (!speechState.switchLive) {
        await _stopListening();
      }
    }
  }

  void statusListener(String status) async {
    if (!_isDisposed) {
      if (speechState.switchLive &&
          status == "done" &&
          speechState.speechEnabled) {
        if (speechState.currentWords.isNotEmpty) {
          speechState.updateLastWords(speechState.currentWords);
          speechState.updateCurrentWords('');
        }
        speechState.updateSpeechEnabled(false);
        await Future.delayed(const Duration(milliseconds: 50));
        await _startListening();
        await _translateText();
      } else if (!speechState.switchLive &&
          speechState.currentWords.isNotEmpty) {
        speechState.updateSpeechEnabled(false);
        speechState.updateLastWords(speechState.currentWords);

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
      // print("MASUK IS DISPOSED");
      try {
        _speechAvailable = await _speech.initialize(
          onError: errorListener,
          onStatus: statusListener,
        );
      } catch (e) {
        print("Error during _initSpeech: $e");
      }
    } else {}
  }

  Future<void> _startListening() async {
    // print("START");
    if (!speechState.speechEnabled) {
      // print("AVAILABLE");
      // print(languageCodes[_selectedLanguage]);
      try {
        speechState.updateSpeechEnabled(true);
        await _speech.listen(
          localeId: languageCodes[_selectedFromLanguage],
          onResult: _onSpeechResult,
          cancelOnError: false,
          partialResults: true,
        );
        // if (mounted) {
        //   setState(() {
        //     _speechEnabled = true;
        //   });
        // }
      } catch (e) {
        print("Error during _startListening: $e");
      }
    } else {
      print("RA LISTEN");
    }
  }

  Future<void> _stopListening() async {
    // }
    // if (!speechState.switchLive) {
    if (!speechState.switchLive) {
      speechState.updateBeforeEdit(false);
    }
    speechState.updateSpeechEnabled(false);
    // }
    await _speech.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // print("MLEBU ON SPEECH");
    if (!_isDisposed) {
      speechState.updateCurrentWords(result.recognizedWords);
      speechState.updateLastWords(speechState.currentWords);
      if (mounted) {
        setState(() {
          _editableController.text = speechState.lastWords;
        });
      }
      // if (mounted) {
      //   setState(() {
      //     // _lastWords = _currentWords;
      //   });
      // }
      // print(_currentWords);
    }
  }

  Future _translateText() async {
    // print("TRENSLET");
    if (_editableController.text.isNotEmpty) {
      print("_editableController.text 111");
      print(_editableController.text);
      try {
        String targetLanguageCode = languageCodes[_selectedLanguage] ?? 'en';
        String fromLanguageCode = languageCodes[_selectedFromLanguage] ?? 'en';

        await translator
            .translate(_editableController.text,
                from: fromLanguageCode, to: targetLanguageCode)
            .then((value) {
          speechState.updateTranslatedText(value.text);
          print("_trslnt");
          print(speechState.translatedText);
        });
        print("_editableController.text");
        print(_editableController.text);
        if (_editableController.text.length > 1 &&
            _editableController.text != temp &&
            speechState.switchLive) {
          User? user = FirebaseAuth.instance.currentUser;
          String displayName = user?.displayName ?? "User";
          FirebaseService firebaseService = FirebaseService();
          await firebaseService.saveTranslationHistory(
              idPair ?? '',
              displayName,
              pairedBluetooth,
              _selectedFromLanguage,
              _selectedLanguage,
              _editableController.text,
              speechState.translatedText);
          temp = _editableController.text;
          // print("Translation history saved successfully.");
        }
      } catch (e) {
        speechState.updateTranslatedText('Error occurred during translation');
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
                      if (mounted) {
                        setState(() {
                          _searchText = value;
                          _filteredLanguages();
                        });
                      }
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
                          if (mounted) {
                            setState(() {
                              _selectedLanguage = filteredLanguages[index];
                            });
                          }
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
                      if (mounted) {
                        setState(() {
                          _searchText = value;
                          _filteredLanguages();
                        });
                      }
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
                          if (mounted) {
                            setState(() {
                              _selectedFromLanguage = filteredLanguages[index];
                            });
                          }
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
    SpeechState speechState = Provider.of<SpeechState>(context);
    Widget header() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
        color: primaryColor500,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
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
      if (!speechState.beforeEdit) {
        _editableController.text = speechState.lastWords;
      }
      if (speechState.switchLive) {
        _editableController.text = speechState.lastWords;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (speechState.lastWords
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
                      speechState.updateLastWords(newText);
                      // if (mounted) {
                      //   setState(() {
                      //     _lastWords = newText;
                      //   });
                      // }
                      if (!isTyping) {
                        await _translateText(); // Panggil terjemahan setelah mengetik selesai
                      }
                      if (newText.isEmpty) {
                        speechState.updateTranslatedText('');
                      }
                    });
                  },
                  decoration: InputDecoration(
                    enabled: speechState.beforeEdit ? false : true,
                    hintStyle: h2Text.copyWith(color: secondaryColor200),
                    hintText: speechState.lastWords.isEmpty &&
                            !speechState.speechEnabled
                        ? "Tekan tombol mikrofon untuk memulai"
                        : speechState.speechEnabled &&
                                speechState.lastWords.isEmpty
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
      // print("trnslt: " + _translatedText);
      print("_trslnt dasodjsaoijaosdj");
      print(speechState.translatedText);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            speechState.translatedText.isEmpty && !speechState.speechEnabled
                ? "Tekan tombol mikrofon untuk memulai"
                : speechState.speechEnabled &&
                        speechState.translatedText.isEmpty
                    ? "Listening..."
                    : 'Me: ${speechState.translatedText}',
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
                              _editableController.text.length.toString(),
                              style: h4Text.copyWith(color: secondaryColor500),
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
                              speechState.translatedText.length.toString(),
                              style: h4Text.copyWith(color: secondaryColor500),
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
                                builder: (context) => PairHistoryPage(
                                  idPair: idPair ?? "",
                                  historyList: historyList,
                                ),
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
                      if (!speechState.speechEnabled) {
                        speechState.updateLastWords('');
                        speechState.updateTranslatedText('');
                        _editableController.text = "";
                        speechState.updateCurrentWords('');
                        speechState.updateBeforeEdit(true);
                        await _startListening();
                      } else {
                        speechState.updateSpeechEnabled(false);
                        if (!speechState.switchLive) {
                          speechState.updateBeforeEdit(false);
                        }
                        await _stopListening();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 52),
                      padding: EdgeInsets.symmetric(
                        horizontal: speechState.speechEnabled ? 22 : 25,
                        vertical: speechState.speechEnabled ? 22 : 17,
                      ),
                      decoration: BoxDecoration(
                        color: speechState.speechEnabled
                            ? errorColor500
                            : (_speechAvailable && !speechState.speechEnabled
                                ? primaryColor500
                                : primaryColor500),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: speechState.speechEnabled
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
                      children: speechState.switchLive
                          ? speechState.speechEnabled
                              ? [const SizedBox()]
                              : [
                                  CupertinoSwitch(
                                      trackColor: secondaryColor100,
                                      activeColor: secondaryColor500,
                                      value: speechState.switchLive,
                                      onChanged: (bool value) {
                                        speechState.updateSwitch(value);
                                      }),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Live",
                                    style: h4Text.copyWith(
                                        color: secondaryColor200),
                                  ),
                                ]
                          : !speechState.speechEnabled && speechState.beforeEdit
                              ? [
                                  CupertinoSwitch(
                                      trackColor: secondaryColor100,
                                      activeColor: secondaryColor500,
                                      value: speechState.switchLive,
                                      onChanged: (bool value) {
                                        speechState.updateSwitch(value);
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
                                      if (!speechState.speechEnabled) {
                                        speechState.updateBeforeEdit(true);
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
                                          speechState.lastWords,
                                          speechState.translatedText,
                                        );
                                        // if (mounted) {
                                        // print("COCOTE");
                                        //   setState(() {
                                        //     _beforeEdit = true;
                                        //   });
                                        // }
                                      }
                                    },
                                    child: Icon(
                                      Icons.send,
                                      color: speechState.speechEnabled
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

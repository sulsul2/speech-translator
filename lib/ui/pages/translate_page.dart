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
import 'package:speech_translator/ui/pages/home_page.dart';
import 'package:speech_translator/ui/pages/pair_history_page.dart';
import 'package:translator/translator.dart';

class TranslatePage extends StatefulWidget {
  final bool isToUid;
  final TextEditingController editableController;
  const TranslatePage(
      {super.key, required this.isToUid, required this.editableController});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

bool _isTranslating = false;
bool _isDisposed = false; // Tambahkan flag untuk melacak status dispose
GoogleTranslator translator = GoogleTranslator();
bool _speechAvailable = false;

class _TranslatePageState extends State<TranslatePage> {
  late SpeechState speechState;
  final SpeechToText _speech = SpeechToText();
  TextEditingController searchController = TextEditingController();
  String _searchText = '';
  String? idPair = '';
  List<History> _currentData = [];
  String pairedBluetooth = '';
  String _currentUser = '';
  Timer? _debounce;

  List<String> filteredLanguages = [];
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
      Map<String, History> fetchedHistory =
          await firebaseService.fetchPairedTranslationHistory(idPair);
      speechState.updateHistoryList(fetchedHistory);
    }
  }

  @override
  void initState() {
    super.initState();
    Timer? _debounceTimer; // Timer untuk debounce

    widget.editableController.addListener(() async {
      final newText = widget.editableController.text;

      // Batalkan timer sebelumnya jika ada
      if (!speechState.isMic && speechState.switchLive) {
        _debounceTimer?.cancel();

        // Mulai timer baru untuk cek jika tidak ada perubahan dalam 3 detik
        _debounceTimer = Timer(Duration(seconds: 5), () async {
          // print("cek" + newText);
          if (widget.editableController.text == newText) {
            // print("text" + newText);
            // Jika teks tidak berubah selama 3 detik, kosongkan
            // speechState.updateLastWords("");
            // setState(() {
            //   widget.editableController.text = "";
            // });
            // speechState.updateTempText("");
            // speechState.updateTranslatedText(""); // Kosongkan hasil terjemahan
            // speechState.updateIsThree(true);
            await _stopListening();
          }
        });
      }

      // Jika teks berubah
      if (newText.isNotEmpty && newText != speechState.temp) {
        await _translateText();
        // speechState.updateTempText(newText);
      } else if (newText.isEmpty) {
        speechState.updateTranslatedText(
            ""); // Kosongkan hasil terjemahan jika teks kosong
      }
    });

    getInit();
  }

  getInit() {
    _initSpeech();
    _isDisposed = false;

    speechState = Provider.of<SpeechState>(context, listen: false);
    _filteredLanguages();
    fetchDataFromFirebase();
    _setupRealtimeTranslations();
    _isTranslating = false;
    _isDisposed = false; // Tambahkan flag untuk melacak status dispose
    translator = GoogleTranslator();

    // _speechEnabled = false;
    _speechAvailable = false;
    // _lastWords = '';
    // _translatedText = '';
    // _selectedLanguage = 'Bahasa Indonesia';
    // _selectedFromLanguage = 'English';
    // _beforeEdit = true;
  }

  @override
  void dispose() {
    super.dispose();
    _debounce?.cancel();
    widget.editableController.removeListener(() {});
    _isDisposed = true; // Tandai widget sebagai telah dihancurkan
    widget.editableController.dispose();
    _translationSubscription?.cancel();
    _stopListening(); // Pastikan sesi mendengarkan dihentikan
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
            !realtimeTranslations.containsKey(key)) {
          if (data['pairedBluetooth'] == _currentUser) {
            if (!_isDisposed) {
              if (mounted) {
                setState(() {
                  realtimeTranslations[key] = History.fromJson(data);
                  speechState.addHistoryList(key, data);
                  _currentData.add(History.fromJson(data));
                });
              }
            }
          } else if (data['username'] == _currentUser &&
              speechState.historyList.containsKey(key)) {
            speechState.addHistoryList(key, data);
          }
        }

        // User? user = FirebaseAuth.instance.currentUser;
        // String username = user?.displayName ?? '';
        // if (data['username'] == username) {
        //   if (!_isDisposed) {
        //     if (mounted) {
        //       setState(() {
        //         historyList.add(History.fromJson(data));
        //       });
        //     }
        //   }
        // } else if (data['pairedBluetooth'] == username) {
        //   setState(() {
        //     historyList.add(History.fromJson(data));
        //   });
        // }
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
      if (speechState.switchLive && status == "done" && !speechState.isMic) {
        if (speechState.currentWords.isNotEmpty) {
          speechState.updateLastWords(speechState.currentWords);
          speechState.updateCurrentWords('');
        }
        // speechState.updateSpeechEnabled(false);
        // print("halo halo");
        // await Future.delayed(const Duration(milliseconds: 50));
        await _stopListening();
        await _startListening();
        await _translateText();
        // print("haiiii" + widget.editableController.text);
        // print("tempe" + speechState.temp);
        if (widget.editableController.text != speechState.temp &&
            widget.editableController.text != "") {
          // print("tahu" + speechState.temp);
          User? user = FirebaseAuth.instance.currentUser;
          String displayName = user?.displayName ?? "User";
          FirebaseService firebaseService = FirebaseService();
          await firebaseService.saveTranslationHistory(
              idPair ?? '',
              displayName,
              pairedBluetooth,
              speechState.selectedFromLanguage,
              speechState.selectedLanguage,
              widget.editableController.text,
              speechState.translatedText);
          speechState.updateTempText(widget.editableController.text);
        }
      } else if (!speechState.switchLive &&
          speechState.currentWords.isNotEmpty) {
        if (speechState.speechEnabled) {
          await _stopListening();
        }
        speechState.updateSpeechEnabled(false);
        await _translateText();
      } else {
        // print("TT");
      }
    } else {
      // print("JMBUTT");
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
        if (speechState.switchLive) {
          await _speech.listen(
              localeId: languageCodes[speechState.selectedFromLanguage],
              onResult: _onSpeechResult,
              cancelOnError: false,
              partialResults: true,
              onDevice: true
              // listenFor: const Duration(seconds: 10),
              );
        } else {
          await _speech.listen(
              localeId: languageCodes[speechState.selectedFromLanguage],
              onResult: _onSpeechResult,
              cancelOnError: false,
              partialResults: true,
              onDevice: true);
        }
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
    // speechState.updateIsMic(true);
    // }
    await _speech.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // print("MLEBU ON SPEECH");
    if (!_isDisposed) {
      String tempAgain = result.recognizedWords;
      // if (speechState.isThree) {
      //    tempAgain = result.recognizedWords
      //       .substring(speechState.tempText.length)
      //       .trim();
      // }
      speechState.updateCurrentWords(tempAgain);
      speechState.updateLastWords(speechState.currentWords);
      widget.editableController.text = speechState.lastWords;
      // speechState.updateTempTextAgain(result.recognizedWords);
      // if (mounted) {
      //   setState(() {
      //     // _lastWords = _currentWords;
      //   });
      // }
      // print(_currentWords);
    }
  }

  void _updateText(String newText) {
    // Simpan posisi kursor saat ini
    final cursorPosition = widget.editableController.selection;

    // Tentukan posisi baru jika teks berubah
    int newCursorOffset = cursorPosition.baseOffset;
    if (newText.length < widget.editableController.text.length) {
      newCursorOffset =
          cursorPosition.baseOffset - 1; // Sesuaikan saat penghapusan teks
    } else if (newText.length > widget.editableController.text.length) {
      newCursorOffset =
          cursorPosition.baseOffset + 1; // Sesuaikan saat penambahan teks
    }

    // Perbarui teks dan atur posisi kursor
    widget.editableController.text = newText;
    widget.editableController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorOffset.clamp(0, newText.length)),
    );
  }

  Future _translateText() async {
    // print("TRENSLET");
    if (widget.editableController.text.isNotEmpty) {
      // print("widget.editableController.text 111");
      // print(widget.editableController.text);
      try {
        String targetLanguageCode =
            languageCodes[speechState.selectedLanguage] ?? 'en';
        String fromLanguageCode =
            languageCodes[speechState.selectedFromLanguage] ?? 'en';

        await translator
            .translate(widget.editableController.text,
                from: fromLanguageCode, to: targetLanguageCode)
            .then((value) {
          speechState.updateTranslatedText(value.text);
          // print("_trslnt");
          // print(speechState.translatedText);
        });
        // print("widget.editableController.text");
        // print(widget.editableController.text);
        // if (widget.editableController.text.length > 1 &&
        //     widget.editableController.text != speechState.temp &&
        //     speechState.switchLive) {
        //   User? user = FirebaseAuth.instance.currentUser;
        //   String displayName = user?.displayName ?? "User";
        //   FirebaseService firebaseService = FirebaseService();
        //   await firebaseService.saveTranslationHistory(
        //       idPair ?? '',
        //       displayName,
        //       pairedBluetooth,
        //       speechState.selectedFromLanguage,
        //       speechState.selectedLanguage,
        //       widget.editableController.text,
        //       speechState.translatedText);
        //   speechState.updateTempText(widget.editableController.text);
        //   // print("Translation history saved successfully.");
        // }
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
                          speechState
                              .updateSelectedLanguage(filteredLanguages[index]);
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
                          speechState.updateSelectedFromLanguage(
                              filteredLanguages[index]);
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
                // Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomePage()));
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

    Widget _buildOriginalTextSection() {
      if (!speechState.beforeEdit) {
        _updateText(speechState.lastWords);
      }
      if (speechState.switchLive) {
        // print("test" + widget.editableController.text);
        // if (speechState.isThree) {
        // print("tast" + widget.editableController.text);
        // widget.editableController.text = "";
        // // print(widget.editableController.text);
        // speechState.updateLastWords("");
        // speechState.updateTranslatedText("");
        // speechState.updateIsThree(false);
        // }
        widget.editableController.text = speechState.lastWords;
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
                  controller: widget.editableController,
                  // enabled: _beforeEdit ? false : true,
                  onChanged: (newText) {
                    speechState.updateIsTyping(true); // Tandai sedang mengetik
                    // if (_debounce?.isActive ?? false) _debounce!.cancel();

                    speechState.updateLastWords(newText);
                    speechState.updateIsTyping(
                        false); // Tandai selesai mengetik setelah 500 ms tanpa input baru
                    // _debounce =
                    //     Timer(const Duration(milliseconds: 500), () async {
                    //   // if (mounted) {
                    //   //   setState(() {
                    //   //     _lastWords = newText;
                    //   //   });
                    //   // }
                    // });
                    // if (!speechState.isTyping) {
                    //   await _translateText(); // Panggil terjemahan setelah mengetik selesai
                    // }
                    if (newText.isEmpty) {
                      speechState.updateTranslatedText('');
                    }
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
      // print("_trslnt dasodjsaoijaosdj");
      // print(speechState.translatedText);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            speechState.translatedText.isEmpty && !speechState.speechEnabled
                ? "Tekan tombol mikrofon untuk memulai"
                : speechState.speechEnabled &&
                        speechState.translatedText.isEmpty
                    ? "Listening..."
                    : widget.editableController.text == ""
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
                                    speechState.selectedFromLanguage,
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
                              widget.editableController.text.length.toString(),
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
                                    speechState.selectedLanguage,
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
                                  historyList: speechState.historyList,
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
                      speechState.updateIsMic(!speechState.isMic);
                      if (!speechState.isMic) {
                        speechState.updateLastWords('');
                        speechState.updateTranslatedText('');
                        widget.editableController.text = "";
                        speechState.updateCurrentWords('');
                        speechState.updateBeforeEdit(true);
                        await _startListening();
                      } else {
                        speechState.updateSpeechEnabled(false);
                        if (!speechState.switchLive) {
                          speechState.updateBeforeEdit(false);
                        } else {
                          if (widget.editableController.text !=
                                  speechState.temp &&
                              widget.editableController.text != '') {
                            User? user = FirebaseAuth.instance.currentUser;
                            String displayName = user?.displayName ?? "User";
                            FirebaseService firebaseService = FirebaseService();
                            await firebaseService.saveTranslationHistory(
                                idPair ?? '',
                                displayName,
                                pairedBluetooth,
                                speechState.selectedFromLanguage,
                                speechState.selectedLanguage,
                                widget.editableController.text,
                                speechState.translatedText);
                          }
                        }
                        await _stopListening();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 52),
                      padding: EdgeInsets.symmetric(
                        horizontal: !speechState.isMic ? 22 : 25,
                        vertical: !speechState.isMic ? 22 : 17,
                      ),
                      decoration: BoxDecoration(
                        color: !speechState.isMic
                            ? errorColor500
                            : (_speechAvailable && speechState.isMic
                                ? primaryColor500
                                : primaryColor500),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: !speechState.isMic
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
                          ? !speechState.isMic
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
                                          speechState.selectedFromLanguage,
                                          speechState.selectedLanguage,
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

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
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

bool _isDisposed = false;
GoogleTranslator translator = GoogleTranslator();
bool speechAvailable = false;

class _TranslatePageState extends State<TranslatePage> {
  late SpeechState speechState;
  final SpeechToText _speech = SpeechToText();
  TextEditingController searchController = TextEditingController();
  List<History> currentData = [];
  String pairedBluetooth = '';
  String _currentUser = '';
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

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

    Map<String, String>? pairingInfo =
        await firebaseService.getIdPair(user!.uid, widget.isToUid);

    if (pairingInfo != null) {
      String? pairUid = pairingInfo['pairUid'];
      if (pairUid != null) {
        String? username = await firebaseService.getUsernameFromUid(pairUid);
        if (username != null) {
          if (!_isDisposed) {
            speechState.updateIdPair(pairingInfo['idPair']!);
            if (mounted) {
              setState(() {
                pairedBluetooth = username;
              });
            }
          }
        }
      }
    }

    if (!_isDisposed) {
      Map<String, History> fetchedHistory = await firebaseService
          .fetchPairedTranslationHistory(speechState.idPair);
      speechState.updateHistoryList(fetchedHistory);
    }
  }

  @override
  void initState() {
    super.initState();
    Timer? debounceTimer;

    widget.editableController.addListener(() async {
      final newText = widget.editableController.text;

      if (!speechState.isMic && speechState.switchLive) {
        debounceTimer?.cancel();

        debounceTimer = Timer(const Duration(seconds: 2), () async {
          if (widget.editableController.text == newText) {
            // await _stopListening();
            if (widget.editableController.text != "" &&
                widget.editableController.text != speechState.temp) {
              User? user = FirebaseAuth.instance.currentUser;
              String displayName = user?.displayName ?? "User";
              FirebaseService firebaseService = FirebaseService();
              speechState.updateTempText(widget.editableController.text);
              speechState
                  .updateMainTemp(speechState.mainTemp + speechState.temp);
              await firebaseService.saveTranslationHistory(
                  speechState.idPair,
                  displayName,
                  pairedBluetooth,
                  speechState.selectedFromLanguage,
                  speechState.selectedLanguage,
                  widget.editableController.text,
                  speechState.translatedText);
            }
            speechState.updateLastWords("");
          }
        });
      }

      if (newText.isNotEmpty && newText != speechState.temp) {
        speechState.updateIsTranslating(true);
        Timer(Duration(seconds: speechState.switchLive ? 0 : 1), () async {
          await _translateText();
        });
        if (!speechState.switchLive) {
          speechState.updateTempText(newText);
        }
      } else if (newText.isEmpty) {
        speechState.updateTranslatedText("");
      }
    });

    getInit();
  }

  getInit() async {
    _initSpeech();

    _isDisposed = false;
    speechState = Provider.of<SpeechState>(context, listen: false);
    _filteredLanguages();
    fetchDataFromFirebase();
    _setupRealtimeTranslations();
    _isDisposed = false;
    translator = GoogleTranslator();
    speechAvailable = false;
  }

  @override
  void dispose() {
    super.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    _scrollController.dispose();
    widget.editableController.removeListener(() {});
    _isDisposed = true;
    widget.editableController.dispose();
    _translationSubscription?.cancel();
    _stopListening();
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
              value['idPair'] == speechState.idPair &&
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
        if (data['idPair'] == speechState.idPair &&
            !realtimeTranslations.containsKey(key)) {
          if (data['pairedBluetooth'] == _currentUser) {
            if (!_isDisposed) {
              if (mounted) {
                setState(() {
                  realtimeTranslations[key] = History.fromJson(data);
                  speechState.addHistoryList(key, data);
                  currentData.add(History.fromJson(data));
                });
                if (speechState.historyListLength !=
                    speechState.historyList.length) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                    speechState.updateHistoryListLength(
                        speechState.historyList.length);
                  });
                }
              }
            }
          } else if (data['username'] == _currentUser &&
              speechState.historyList.containsKey(key)) {
            speechState.addHistoryList(key, data);
          }
          if (speechState.historyListLength != speechState.historyList.length) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              speechState
                  .updateHistoryListLength(speechState.historyList.length);
            });
          }
        }
      }
    });
  }

  void _filteredLanguages() {
    List<String> allLanguages = languageCodes.keys.toList();

    if (speechState.searchText.isEmpty) {
      // Jika search kosong, kembalikan semua bahasa
      speechState.updateFilteredLanguageText(allLanguages);
    } else {
      // Filter bahasa yang mengandung text search
      List<String> filtered = allLanguages
          .where((language) => language
              .toLowerCase()
              .contains(speechState.searchText.toLowerCase()))
          .toList();

      // Update state dengan hasil filter
      speechState.updateFilteredLanguageText(filtered);
    }
  }

  void _initializeFilteredLanguages() {
    // Ambil semua keys dari languageCodes
    List<String> allLanguages = languageCodes.keys.toList();
    // Update filtered languages dengan semua bahasa
    speechState.updateFilteredLanguageText(allLanguages);
  }

  void statusListener(String status) async {
    if (!_isDisposed) {
      if (speechState.switchLive &&
          (status == "done" || status == "notListening") &&
          !speechState.isMic) {
        if (speechState.currentWords.isNotEmpty) {
          speechState.updateLastWords(speechState.currentWords);
          speechState.updateCurrentWords('');
        }
        await _stopListening();
        await _startListening();
        await _translateText();
      } else if (!speechState.switchLive &&
          speechState.currentWords.isNotEmpty) {
        if (speechState.speechEnabled) {
          await _stopListening();
        }
        speechState.updateSpeechEnabled(false);
        await _translateText();
      }
    }
  }

  void _initSpeech() async {
    if (!_isDisposed) {
      try {
        speechAvailable = await _speech.initialize(
          onStatus: statusListener,
        );
      } catch (e) {
        print("Error during _initSpeech: $e");
      }
    } else {}
  }

  Future<void> _startListening() async {
    if (!speechState.speechEnabled) {
      try {
        speechState.updateSpeechEnabled(true);
        if (speechState.switchLive) {
          await _speech.listen(
            localeId: languageCodes[speechState.selectedFromLanguage],
            onResult: _onSpeechResult,
            cancelOnError: false,
            partialResults: true,
            onDevice: true,
            listenFor: const Duration(hours: 10),
          );
        } else {
          await _speech.listen(
              localeId: languageCodes[speechState.selectedFromLanguage],
              onResult: _onSpeechResult,
              cancelOnError: false,
              partialResults: true,
              onDevice: true);
        }
      } catch (e) {
        print("Error during _startListening: $e");
      }
    }
  }

  Future<void> _stopListening() async {
    speechState.updateSpeechEnabled(false);
    if (!speechState.switchLive) {
      speechState.updateBeforeEdit(false);
    } else {
      widget.editableController.text = speechState.temp;
    }
    speechState.updateIsTranslating(false);
    speechState.updateMainTemp("");

    await _speech.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!_isDisposed) {
      String fullText = result.recognizedWords;

      // Get new text by using the length of mainTemp as starting index
      if (speechState.mainTemp.isNotEmpty) {
        int startIndex = speechState.mainTemp.length;
        if (startIndex < fullText.length) {
          speechState.updateCurrentWords(fullText.substring(startIndex).trim());
        }
      } else {
        speechState.updateCurrentWords(fullText);
      }

      // Update current words with just the new portion

      // Update last words based on mic state
      if (speechState.isMic) {
        speechState.updateLastWords(speechState.temp);
      } else {
        speechState.updateLastWords(speechState.currentWords);
      }

      widget.editableController.text = speechState.lastWords;
    }
  }

  Future _translateText() async {
    if (widget.editableController.text.isNotEmpty) {
      try {
        String targetLanguageCode =
            languageCodes[speechState.selectedLanguage] ?? 'en';
        String fromLanguageCode =
            languageCodes[speechState.selectedFromLanguage] ?? 'en';
        if (!speechState.switchLive) {
          widget.editableController.text = speechState.lastWords;
        }

        await translator
            .translate(widget.editableController.text,
                from: fromLanguageCode, to: targetLanguageCode)
            .then((value) {
          speechState.updateTranslatedText(value.text);
        });
        speechState.updateTempTranslatedText(speechState.translatedText);
      } catch (e) {
        speechState.updateTranslatedText('Error occurred during translation');
      } finally {
        speechState.updateIsTranslating(false);
      }
    }
  }

  void _showLanguageSelection() {
    searchController.clear();
    speechState.updateSearchText('');
    _initializeFilteredLanguages();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            speechState.updateSearchText(value);
                            _filteredLanguages();
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: Consumer<SpeechState>(
                        builder: (context, state, _) {
                          return GridView.builder(
                            itemCount: state.filteredLanguages.length,
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
                                  state.updateSelectedLanguage(
                                      state.filteredLanguages[index]);
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 32),
                                  child: Text(
                                    state.filteredLanguages[index],
                                    style: bodyMText.copyWith(
                                        color: secondaryColor500,
                                        fontWeight: semibold),
                                  ),
                                ),
                              );
                            },
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
      },
    );
  }

  void _showFromLanguageSelection() {
    // Reset search saat dialog dibuka
    searchController.clear();
    speechState.updateSearchText('');
    _initializeFilteredLanguages();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            speechState.updateSearchText(value);
                            _filteredLanguages();
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: Consumer<SpeechState>(
                        builder: (context, state, _) {
                          return GridView.builder(
                            itemCount: state.filteredLanguages.length,
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
                                  state.updateSelectedFromLanguage(
                                      state.filteredLanguages[index]);
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 32),
                                  child: Text(
                                    state.filteredLanguages[index],
                                    style: bodyMText.copyWith(
                                        color: secondaryColor500,
                                        fontWeight: semibold),
                                  ),
                                ),
                              );
                            },
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.editableController.text.isNotEmpty)
                Text(
                  "Me: ",
                  style: h2Text.copyWith(color: secondaryColor200),
                ),
              Expanded(
                child: TextFormField(
                  controller: widget.editableController,
                  onChanged: (newText) {
                    speechState.updateIsTyping(true);
                    speechState.updateLastWords(newText);
                    speechState.updateIsTyping(false);
                    if (newText.isEmpty) {
                      speechState.updateTranslatedText('');
                    }
                  },
                  enableInteractiveSelection: true,
                  showCursor: true,
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
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
                    border: InputBorder.none,
                  ),
                  style: h2Text.copyWith(color: secondaryColor200),
                  maxLines: null,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildTranslatedTextSection() {
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
                        : 'Me: ${speechState.isTranslating ? "${speechState.tempTranslatedText}..." : speechState.tempTranslatedText}',
            style: h2Text.copyWith(color: secondaryColor200),
          ),
        ],
      );
    }

    Widget historySection() {
      final historyEntries = speechState.historyList.entries.toList();
      return speechState.loading
          ? Center(
              child: LoadingAnimationWidget.flickr(
                  leftDotColor: const Color(0xff2A46FF),
                  rightDotColor: secondaryColor400,
                  size: 32),
            )
          : speechState.historyList.isEmpty
              ? const Center(
                  child: Text(
                    'No history available',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: historyEntries.length,
                  shrinkWrap: true,
                  reverse: false,
                  itemBuilder: (context, index) {
                    final entry = historyEntries[index];
                    final historyItem = entry.value;
                    User? user = FirebaseAuth.instance.currentUser;
                    String username = user?.displayName ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: username == historyItem.username ? 0 : 40,
                              height: username == historyItem.username ? 0 : 40,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadiusDirectional.circular(100),
                                  color: username == historyItem.username
                                      ? primaryColor500
                                      : grayColor300),
                            ),
                            SizedBox(
                              width: username == historyItem.username ? 16 : 0,
                            ),
                            Expanded(
                              child: ChatBubble(
                                clipper: ChatBubbleClipper8(
                                    type: username == historyItem.username
                                        ? BubbleType.sendBubble
                                        : BubbleType.receiverBubble),
                                alignment: username == historyItem.username
                                    ? Alignment.topRight
                                    : Alignment.topLeft,
                                margin: const EdgeInsets.only(top: 20),
                                backGroundColor:
                                    username == historyItem.username
                                        ? primaryColor50
                                        : grayColor25,
                                child: Column(
                                  crossAxisAlignment:
                                      username == historyItem.username
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      textAlign:
                                          username == historyItem.username
                                              ? TextAlign.end
                                              : TextAlign.start,
                                      historyItem.realWord,
                                      overflow: TextOverflow.visible,
                                      style: username == historyItem.username
                                          ? bodyMText.copyWith(
                                              color: username ==
                                                      historyItem.username
                                                  ? secondaryColor400
                                                  : grayColor400,
                                              fontWeight: bold)
                                          : bodyXSText.copyWith(
                                              color: username ==
                                                      historyItem.username
                                                  ? secondaryColor400
                                                  : grayColor400),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      textAlign:
                                          username == historyItem.username
                                              ? TextAlign.end
                                              : TextAlign.start,
                                      overflow: TextOverflow.visible,
                                      historyItem.translatedWord,
                                      style: username != historyItem.username
                                          ? bodyMText.copyWith(
                                              color: username ==
                                                      historyItem.username
                                                  ? secondaryColor400
                                                  : grayColor400,
                                              fontWeight: bold)
                                          : bodyXSText.copyWith(
                                              color: username ==
                                                      historyItem.username
                                                  ? secondaryColor400
                                                  : grayColor400),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: username == historyItem.username ? 0 : 16,
                            ),
                            Container(
                              width: username == historyItem.username ? 40 : 0,
                              height: username == historyItem.username ? 40 : 0,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadiusDirectional.circular(100),
                                  color: username == historyItem.username
                                      ? primaryColor500
                                      : grayColor300),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
    }

    Widget mainContent() {
      return Container(
        margin: const EdgeInsets.only(top: 90),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 36),
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
                                  Expanded(
                                    child: Container(
                                      color: primaryColor50,
                                      width: double.infinity,
                                      // height: 150,
                                      child: SingleChildScrollView(
                                        child: _buildOriginalTextSection(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        widget.editableController.text.length
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
                              color: whiteColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 36),
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
                                  Expanded(
                                    child: Container(
                                      color: whiteColor,
                                      width: double.infinity,
                                      // height: 150,
                                      child: SingleChildScrollView(
                                        child: _buildTranslatedTextSection(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        speechState.translatedText.length
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
                            Text("History Transcript",
                                style: bodyLText.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: secondaryColor500)),
                            const SizedBox(
                              height: 8,
                            ),
                            Expanded(child: historySection())
                          ],
                        )),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.sizeOf(context).height * 0.15,
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                  idPair: speechState.idPair,
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
                        speechState.updateTempTranslatedText('');
                        widget.editableController.text = "";
                        speechState.updateCurrentWords('');
                        speechState.updateBeforeEdit(true);
                        await _startListening();
                      } else {
                        speechState.updateIsTranslating(false);
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
                            speechState
                                .updateTempText(widget.editableController.text);
                            await _translateText();
                            await firebaseService.saveTranslationHistory(
                                speechState.idPair,
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
                      child: !speechState.isMic
                          ? Image.asset(
                              'assets/stop_button.png',
                              height: 90,
                            )
                          : Image.asset(
                              'assets/mic_button.png',
                              height: 90,
                            ),
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
                              : widget.editableController.text == ""
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
                                            User? user = FirebaseAuth
                                                .instance.currentUser;
                                            String displayName =
                                                user?.displayName ?? "User";
                                            FirebaseService firebaseService =
                                                FirebaseService();
                                            await firebaseService
                                                .saveTranslationHistory(
                                              speechState.idPair,
                                              displayName,
                                              pairedBluetooth,
                                              speechState.selectedFromLanguage,
                                              speechState.selectedLanguage,
                                              speechState.lastWords,
                                              speechState.translatedText,
                                            );
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

import 'package:flutter/material.dart';
import 'package:speech_translator/models/history_model.dart';

class SpeechState with ChangeNotifier {
  bool _speechEnabled = false;
  bool _beforeEdit = true;
  bool _switchLive = false;
  String? _translatedText;
  String? _tempTranslatedText;
  String? _lastWords;
  String? _currentWords;
  Map<String, History> _historyList = {};
  String? _temp;
  bool _isTyping = false;
  String _selectedLanguage = "Bahasa Indonesia";
  String _selectedFromLanguage = "English";
  String? _idPair;
  bool _isMic = true;
  bool _isTranslating = false;
  String? _searchText;
  List<String> _filteredLanguages = [];
  bool _loading = false;

  bool get loading => _loading;
  bool get speechEnabled => _speechEnabled;
  bool get switchLive => _switchLive;
  bool get beforeEdit => _beforeEdit;
  String get translatedText => _translatedText ?? '';
  String get idPair => _idPair ?? '';
  String get tempTranslatedText => _tempTranslatedText ?? '';
  String get lastWords => _lastWords ?? '';
  String get currentWords => _currentWords ?? '';
  Map<String, History> get historyList => _historyList;
  String get temp => _temp ?? '';
  bool get isTyping => _isTyping;
  String get selectedLanguage => _selectedLanguage;
  String get selectedFromLanguage => _selectedFromLanguage;
  bool get isMic => _isMic;
  bool get isTranslating => _isTranslating;
  String get searchText => _searchText ?? '';
  List<String> get filteredLanguages => _filteredLanguages;

  void updateIdPair(String value) {
    if (_idPair == value) return; // Hindari pemanggilan yang tidak perlu
    _idPair = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateLoading(bool value) {
    if (_loading == value) return; // Hindari pemanggilan yang tidak perlu
    _loading = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateSpeechEnabled(bool value) {
    if (_speechEnabled == value) return; // Hindari pemanggilan yang tidak perlu
    _speechEnabled = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateSwitch(bool value) {
    if (_switchLive == value) return; // Hindari pemanggilan yang tidak perlu
    _switchLive = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateIsMic(bool value) {
    if (_isMic == value) return; // Hindari pemanggilan yang tidak perlu
    _isMic = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateIsTranslating(bool value) {
    if (_isTranslating == value) return; // Hindari pemanggilan yang tidak perlu
    _isTranslating = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateIsTyping(bool value) {
    if (_isTyping == value) return; // Hindari pemanggilan yang tidak perlu
    _isTyping = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateBeforeEdit(bool value) {
    if (_beforeEdit == value) return; // Hindari pemanggilan yang tidak perlu
    _beforeEdit = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateLastWords(String value) {
    if (_lastWords == value) return; // Hindari pemanggilan yang tidak perlu
    _lastWords = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateSelectedLanguage(String value) {
    if (_selectedLanguage == value)
      return; // Hindari pemanggilan yang tidak perlu
    _selectedLanguage = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateSelectedFromLanguage(String value) {
    if (_selectedFromLanguage == value)
      return; // Hindari pemanggilan yang tidak perlu
    _selectedFromLanguage = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateCurrentWords(String value) {
    if (_currentWords == value) return; // Hindari pemanggilan yang tidak perlu
    _currentWords = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addHistoryList(String key, Map<dynamic, dynamic> hist) {
    _historyList[key] = History.fromJson(hist);

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateHistoryList(Map<String, History> hist) {
    _historyList = hist;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateTranslatedText(String value) {
    if (_translatedText == value)
      return; // Hindari pemanggilan yang tidak perlu
    _translatedText = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateSearchText(String value) {
    if (_searchText == value) return; // Hindari pemanggilan yang tidak perlu
    _searchText = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateTempTranslatedText(String value) {
    if (_tempTranslatedText == value)
      return; // Hindari pemanggilan yang tidak perlu
    _tempTranslatedText = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateTempText(String value) {
    if (_temp == value) return; // Hindari pemanggilan yang tidak perlu
    _temp = value;

    // Panggil notifyListeners hanya jika diperlukan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateFilteredLanguageText(List<String> value) {
    // Gunakan List.from untuk membuat copy baru dari list
    _filteredLanguages = List.from(value);

    // Notifikasi listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

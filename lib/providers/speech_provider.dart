import 'package:flutter/material.dart';

class SpeechState with ChangeNotifier {
  bool _speechEnabled = false;
  bool _beforeEdit = true;
  bool _switchLive = false;
  String? _translatedText;
  String? _lastWords;
  String? _currentWords;

  bool get speechEnabled => _speechEnabled;
  bool get switchLive => _switchLive;
  bool get beforeEdit => _beforeEdit;
  String get translatedText => _translatedText ?? '';
  String get lastWords => _lastWords ?? '';
  String get currentWords => _currentWords ?? '';

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

  void updateBeforeEdit(bool value) {
    if (_beforeEdit == value) return; // Hindari pemanggilan yang tidak perlu
    _beforeEdit = value;

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

  void updateLastWords(String value) {
    if (_lastWords == value) return; // Hindari pemanggilan yang tidak perlu
    _lastWords = value;

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
}

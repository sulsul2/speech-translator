import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PairedProvider extends ChangeNotifier {
  String _pairedDevice = '';
  bool _isToUid = false;

  String get pairedDevice => _pairedDevice;
  bool get isToUid => _isToUid;

  void updatePairedDevice(String device) {
    _pairedDevice = device;
    notifyListeners();
  }

  void updateIsToUid(bool device) {
    _isToUid = device;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

import 'package:flutter/foundation.dart';

class PairedProvider extends ChangeNotifier {
  String _pairedDevice = '';

  String get pairedDevice => _pairedDevice;

  void updatePairedDevice(String device) {
    _pairedDevice = device;
    notifyListeners();
  }
}

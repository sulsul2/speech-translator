import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_translator/models/history_model.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> saveTranslationHistory(
      String username,
      String pairedBluetooth,
      String firstLang,
      String secondLang,
      String realWord,
      String translatedWord) async {
    String key = _database.child('history').push().key ?? '';

    Map<String, String> historyData = {
      'username': username,
      'pairedBluetooth': pairedBluetooth,
      'firstLang': firstLang,
      'secondLang': secondLang,
      'realWord': realWord,
      'translatedWord': translatedWord,
    };

    await _database.child('history').child(key).set(historyData);
  }

  Future<List<History>> fetchTranslationHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    String username = user?.displayName ?? '';

    DatabaseReference historyRef = _database.child('history');
    DataSnapshot snapshot = await historyRef.get();

    List<History> historyList = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value['username'] == username) {
          History historyItem = History.fromJson(value);
          historyList.add(historyItem);
        }
      });
    }

    return historyList;
  }

  Future<List<String>> fetchAllEmails() async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');
    DataSnapshot snapshot = await usersRef.get();

    List<String> emails = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        emails.add(value['email']);
      });
    }

    return emails;
  }
}

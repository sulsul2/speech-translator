import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:speech_translator/models/history_model.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'package:speech_translator/shared/theme.dart';
import 'package:provider/provider.dart';
import 'package:speech_translator/ui/pages/home_page.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> saveTranslationHistory(
      String idPair,
      String username,
      String pairedBluetooth,
      String firstLang,
      String secondLang,
      String realWord,
      String translatedWord) async {
    String key = _database.child('history').push().key ?? '';

    Map<String, String> historyData = {
      'username': username,
      'idPair': idPair,
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
        } else if (value['pairedBluetooth'] == username) {
          History historyItem = History.fromJson(value);
          historyList.add(historyItem);
        }
      });
    }

    return historyList;
  }

  Future<Map<String, History>> fetchPairedTranslationHistory(
      String? idPair) async {
    DatabaseReference historyRef = _database.child('history');
    DataSnapshot snapshot = await historyRef.get();

    Map<String, History> historyList = {};

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value['idPair'] == idPair) {
          History historyItem = History.fromJson(value);
          historyList[key] = historyItem;
        }
      });
    }

    return historyList;
  }

  Future<Map<String, List<History>>> fetchSessionData() async {
    List<History> fetchedHistory = await fetchTranslationHistory();
    Map<String, List<History>> sessionMap = {};

    for (var historyItem in fetchedHistory) {
      final idPair = historyItem.idPair;
      sessionMap.putIfAbsent(idPair, () => []).add(historyItem);
    }

    return sessionMap;
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

  Future<Map<String, String>> fetchAllEmailsAndUids() async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');
    DataSnapshot snapshot = await usersRef.get();

    Map<String, String> emailsAndUids = {};

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        emailsAndUids[key] = value['email'];
      });
    }

    return emailsAndUids;
  }

  Future<void> saveUserData(String uid, String username, String email) async {
    DatabaseReference usersRef = _database.child('users').child(uid);

    Map<String, String> userData = {
      'username': username,
      'email': email,
    };

    await usersRef.set(userData);
  }

  String generateAlphanumericToken(int length) {
    const chars = '0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<String> processPairingRequest(String uid) async {
    final databaseRef = FirebaseDatabase.instance.ref("pairing_requests");

    // Cek apakah UID sudah ada
    final snapshot = await databaseRef.child(uid).get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final currentStatus = data['status'];
      final currentToken = data['token'];

      if (currentStatus == "token") {
        // Jika status masih "token", kembalikan token yang sudah ada
        // print("Token already exists: $currentToken");
        return currentToken;
      } else if (currentStatus == "accepted") {
        // Jika status "accepted", generate token baru dan perbarui status
        final newToken = generateAlphanumericToken(6);
        await databaseRef.child(uid).update({
          'token': newToken,
          'status': 'token',
        });
        print("Token updated: $newToken");
        return newToken;
      }
    } else {
      // Jika UID belum ada, buat token baru dan tambahkan data ke tabel
      final newToken = generateAlphanumericToken(6);
      await databaseRef.child(uid).set(
          {'fromUid': "", 'token': newToken, 'status': 'token', 'idPair': ""});
      print("New token created: $newToken");
      return newToken;
    }

    // Kondisi fallback (seharusnya tidak terjadi)
    throw Exception("Unexpected error in processPairingRequest");
  }

  //send token invite
  Future<String> sendInvitation(
      BuildContext context, String tokenInput, String userId) async {
    // final databaseRef = FirebaseDatabase.instance.ref(); // Referensi database

    try {
      // Mengambil data dari tabel pairing_requests
      // final snapshot = await databaseRef.child('pairing_requests').get();
      DatabaseReference pairingRef = _database.child('pairing_requests');

      DataSnapshot snapshot = await pairingRef.get();

      if (snapshot.exists) {
        bool tokenMatch = false;
        String? toUid;

        // Mengecek token yang cocok
        Map<dynamic, dynamic> pairingRequests = snapshot.value as Map;
        pairingRequests.forEach((key, value) async {
          if (value['token'] == tokenInput) {
            tokenMatch = true;
            toUid = key;
          } if (value['fromUid'] == userId) {
            print("Hello");
            print(key);
            await pairingRef.child(key).remove();
          }
        });

        if (tokenMatch && toUid != null) {
          // Jika token cocok, update status menjadi "pending"
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          await pairingRef.child(toUid!).set(
              {'status': 'pending', 'fromUid': userId, 'idPair': timestamp, 'token': tokenInput});

          return toUid!;
        } else {
          // Jika token tidak cocok
          return "error";
        }
      } else {
        // Jika tidak ada data pairing_requests
        return "error";
      }
    } catch (error) {
      return "error";
    }
  }

  Future<void> sendPairingRequest(String fromUid, String toUid) async {
    DatabaseReference pairingRef = _database.child('pairing_requests');

    DataSnapshot snapshot = await pairingRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      for (var entry in data.entries) {
        String key = entry.key;
        Map<dynamic, dynamic> pairingData =
            entry.value as Map<dynamic, dynamic>;

        if (pairingData['fromUid'] == fromUid) {
          await pairingRef.child(key).remove();
        }
      }
    }

    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, dynamic> pairingData = {
      'fromUid': fromUid,
      'status': 'pending',
      'idPair': timestamp,
    };

    await pairingRef.child(toUid).set(pairingData);
  }

  void listenForPairingResponse(
    String currentUserUid, {
    required Function onAccepted,
    required Function onRejected,
  }) {
    DatabaseReference pairingRef =
        _database.child('pairing_requests').child(currentUserUid);

    pairingRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> request =
            event.snapshot.value as Map<dynamic, dynamic>;

        String status = request['status'];

        if (status == 'accepted') {
          onAccepted();
        } else if (status == 'rejected') {
          onRejected();
        }
      }
    });
  }

  Stream<bool> listenForPairingRequests(
      String currentUserUid, BuildContext context) {
    final StreamController<bool> streamController = StreamController<bool>();

    DatabaseReference pairingRef =
        _database.child('pairing_requests').child(currentUserUid);

    pairingRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> request =
            event.snapshot.value as Map<dynamic, dynamic>;

        String fromUid = request['fromUid'];
        String status = request['status'];

        if (status == 'pending') {
          DatabaseReference userRef = _database.child('users').child(fromUid);
          DatabaseEvent userEvent = await userRef.once();

          if (userEvent.snapshot.exists) {
            Map<dynamic, dynamic> userData =
                userEvent.snapshot.value as Map<dynamic, dynamic>;
            String? email = userData['email'] as String?;

            if (email != null) {
              _showPairingDialog(email, currentUserUid, context);
              streamController.add(true);
            }
          }
        }
      }
    });

    return streamController.stream;
  }

  void _showPairingDialog(
      String fromDevice, String toDevice, BuildContext context) {
    // Use the current context to avoid the disposed context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          titlePadding:
              const EdgeInsets.only(left: 40, right: 40, top: 40, bottom: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 40),
          actionsPadding: const EdgeInsets.all(40),
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pairing',
            style: h2Text.copyWith(color: secondaryColor500),
            textAlign: TextAlign.left,
          ),
          content: Text(
            "$fromDevice is trying to connect to\nyour device",
            style: bodyLText.copyWith(
                color: secondaryColor500, fontWeight: regular, fontSize: 24),
            textAlign: TextAlign.left,
          ),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _respondToPairingRequest(toDevice, 'rejected');
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 64, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: bodyLText.copyWith(
                          color: secondaryColor500, fontWeight: medium),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _respondToPairingRequest(toDevice, 'accepted');
                      context
                          .read<PairedProvider>()
                          .updatePairedDevice(fromDevice);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor500,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 64, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: bodyLText.copyWith(
                          color: whiteColor, fontWeight: medium),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _respondToPairingRequest(String toUid, String response) async {
    DatabaseReference pairingRef =
        _database.child('pairing_requests').child(toUid);

    await pairingRef.update({
      'status': response,
    });
  }

  Future<Map<String, String>?> getIdPair(String uid, bool isToUid) async {
    DatabaseReference pairingRef = _database.child('pairing_requests');
    DataSnapshot snapshot = await pairingRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      for (var entry in data.entries) {
        Map<dynamic, dynamic> pairingData =
            entry.value as Map<dynamic, dynamic>;

        if (isToUid) {
          if (entry.key == uid) {
            return {
              'idPair': pairingData['idPair'] as String,
              'pairUid': pairingData['fromUid'] as String,
            };
          }
        } else {
          if (pairingData['fromUid'] == uid) {
            return {
              'idPair': pairingData['idPair'] as String,
              'pairUid': entry.key as String,
            };
          }
        }
      }
    }

    return null;
  }

  Future<String?> getUsernameFromUid(String uid) async {
    DatabaseReference userRef = _database.child('users').child(uid);

    DataSnapshot snapshot = await userRef.child('username').get();

    if (snapshot.exists) {
      return snapshot.value as String?;
    } else {
      return null;
    }
  }

  Future<String?> getEmailFromUid(String uid) async {
    DatabaseReference userRef = _database.child('users').child(uid);

    DataSnapshot snapshot = await userRef.child('email').get();

    if (snapshot.exists) {
      return snapshot.value as String?;
    } else {
      return null;
    }
  }
}

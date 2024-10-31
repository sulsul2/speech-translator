import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_translator/models/history_model.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> pairedSessions = [];
  Map<String, List<History>> historyData = {};
  String? selectedPair;

  void fetchSessionData() async {
    FirebaseService firebaseService = FirebaseService();
    Map<String, List<History>> sessionMap =
        await firebaseService.fetchSessionData();

    setState(() {
      pairedSessions = sessionMap.keys.toList();
      historyData = sessionMap;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchSessionData();
  }

  String formatDateFromTimestamp(String timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

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
          Text(
            "All History",
            style: h4Text.copyWith(color: whiteColor),
          ),
          Image.asset(
            'assets/audio_line_icon.png',
            height: 32,
          )
        ],
      ),
    );
  }

  Widget sessionSection() {
    return Column(
      children: pairedSessions.map((idPair) {
        bool isSelected = selectedPair == idPair;
        final histories = historyData[idPair];
        String pairedBluetooth = histories!.isNotEmpty ? histories.first.pairedBluetooth : '';
        String sessionDate = formatDateFromTimestamp(idPair);
        return Column(
          children: [
            ListTile(
              title: Text(
                '$sessionDate with $pairedBluetooth',
                style: h3Text.copyWith(color: blackColor),
              ),
              trailing: Icon(
                isSelected ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() {
                  selectedPair = isSelected ? null : idPair;
                });
              },
            ),
            if (isSelected) historySection(idPair),
          ],
        );
      }).toList(),
    );
  }

  Widget historySection(String idPair) {
    List<History> histories = historyData[idPair] ?? [];
    return histories.isEmpty
        ? const Center(
            child: Text(
              'No history available',
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final historyItem = histories[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 56.0),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: primaryColor500,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 90),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 20),
              child: SingleChildScrollView(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 56.0),
                      child: sessionSection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          header(),
        ],
      ),
    );
  }
}

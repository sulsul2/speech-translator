import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_translator/models/history_model.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'package:speech_translator/services/firebase_services.dart';
import 'package:speech_translator/shared/theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<History> historyList = [];

  void fetchDataFromFirebase() async {
    FirebaseService firebaseService = FirebaseService();
    List<History> fetchedHistory =
        await firebaseService.fetchTranslationHistory();
    setState(() {
      historyList = fetchedHistory;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    // final paired = context.watch<PairedProvider>().pairedDevice;
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
            // Row(
            //   children: [
            //     Image.asset('assets/bluetooth_icon.png'),
            //     const SizedBox(
            //       width: 12,
            //     ),
            //   ],
            // ),
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

    return Scaffold(
      body: Stack(
        children: [
          Container(
            // margin: const EdgeInsets.only(top: 90),
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
                    historySection(),
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

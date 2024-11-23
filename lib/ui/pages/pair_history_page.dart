import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_translator/models/history_model.dart';
import 'package:speech_translator/providers/paired_provider.dart';
import 'package:speech_translator/shared/theme.dart';

class PairHistoryPage extends StatefulWidget {
  final String idPair;
  final Map<String, History> historyList;
  const PairHistoryPage(
      {super.key, required this.idPair, required this.historyList});

  @override
  State<PairHistoryPage> createState() => _PairHistoryPageState();
}

class _PairHistoryPageState extends State<PairHistoryPage> {
  // List<History> historyList = [];
  final ScrollController _scrollController = ScrollController();

  // void fetchSessionData() async {
  //   FirebaseService firebaseService = FirebaseService();
  //   List<History> fetchedHistory =
  //       await firebaseService.fetchPairedTranslationHistory("1732172325828");

  //   setState(() {
  //     historyList = fetchedHistory;
  //   });

  // }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget header(String paired) {
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
            "Paired with $paired",
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
    final historyEntries = widget.historyList.entries.toList();
    return widget.historyList.isEmpty
        ? const Center(
            child: Text(
              'No history available',
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(), // Scrollable area
            itemCount: historyEntries.length,
            itemBuilder: (context, index) {
              final entry = historyEntries[index];
              final historyItem = entry.value;
              User? user = FirebaseAuth.instance.currentUser;
              String username = user?.displayName ?? '';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 56.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: username == historyItem.username
                        ? grayColor25
                        : secondaryColor25,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 24),
                  child: Column(
                    crossAxisAlignment: username == historyItem.username
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Text(
                        historyItem.username,
                        style: bodyMText.copyWith(color: secondaryColor500),
                      ),
                      const SizedBox(height: 4),
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
    final paired = context.watch<PairedProvider>().pairedDevice;
    return Scaffold(
      backgroundColor: primaryColor500,
      body: Column(
        children: [
          header(paired),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: historySection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

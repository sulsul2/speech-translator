class History {
  final String realWord;
  final String translatedWord;
  final String firstLang;
  final String idPair;
  final String secondLang;
  final String pairedBluetooth;

  History(
      {required this.realWord,
      required this.translatedWord,
      required this.firstLang,
      required this.secondLang,
      required this.pairedBluetooth,
      required this.idPair});

  factory History.fromJson(Map<dynamic, dynamic> json) {
    return History(
      realWord: json['realWord'] ?? '',
      translatedWord: json['translatedWord'] ?? '',
      firstLang: json['firstLang'] ?? '',
      secondLang: json['secondLang'] ?? '',
      idPair: json['idPair'] ?? '',
      pairedBluetooth: json['pairedBluetooth'] ?? '',
    );
  }
}

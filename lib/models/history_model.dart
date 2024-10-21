class History {
  final String realWord;
  final String translatedWord;
  final String firstLang;
  final String secondLang;

  History({
    required this.realWord,
    required this.translatedWord,
    required this.firstLang,
    required this.secondLang,
  });

  factory History.fromJson(Map<dynamic, dynamic> json) {
    return History(
      realWord: json['realWord'] ?? '',
      translatedWord: json['translatedWord'] ?? '',
      firstLang: json['firstLang'] ?? '',
      secondLang: json['secondLang'] ?? '',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color blackColor = const Color(0xFF1A1A1A);
Color whiteColor = const Color(0xFFFFFFFF);
Color primaryColor50 = const Color(0xFFEAECFF);
Color primaryColor100 = const Color(0xFFD4DAFF);
Color primaryColor200 = const Color(0xFFA9B5FF);
Color primaryColor300 = const Color(0xFF7F90FF);
Color primaryColor400 = const Color(0xFF546BFF);
Color primaryColor500 = const Color(0xFF2A46FF);
Color primaryColor600 = const Color(0xFF2238CC);
Color primaryColor700 = const Color(0xFF192A99);
Color primaryColor800 = const Color(0xFF2A46FF);
Color secondaryColor25 = const Color(0xFFE6E7F5);
Color secondaryColor50 = const Color(0xFFD4D5E9);
Color secondaryColor100 = const Color(0xFFC2C4DD);
Color secondaryColor200 = const Color(0xFF9EA1C7);
Color secondaryColor300 = const Color(0xFF7A7EAF);
Color secondaryColor400 = const Color(0xFF565B98);
Color secondaryColor500 = const Color(0xFF323881);
Color secondaryColor600 = const Color(0xFF282C67);
Color secondaryColor700 = const Color(0xFF1E214D);
Color secondaryColor800 = const Color(0xFF141634);
Color errorColor500 = const Color(0xFFF04438);
Color successColor500 = const Color(0xFF12B669);
Color grayColor25 = const Color(0xFFF0F0F0);
Color grayColor50 = const Color(0xFFE0E0E0);
Color grayColor100 = const Color(0xFFC6C6C6);
Color grayColor200 = const Color(0xFFA8A8A8);
Color grayColor300 = const Color(0xFF8D8D8D);
Color grayColor400 = const Color(0xFF6B6B6B);
Color grayColor500 = const Color(0xFF515152);
Color grayColor600 = const Color(0xFF393939);
Color grayColor700 = const Color(0xFF252525);
Color grayColor800 = const Color(0xFF161616);

TextStyle titleText = GoogleFonts.manrope(fontSize: 64, fontWeight: semibold);
TextStyle h1Text = GoogleFonts.manrope(fontSize: 32, fontWeight: semibold);
TextStyle h2Text = GoogleFonts.manrope(fontSize: 24, fontWeight: semibold);
TextStyle h3Text = GoogleFonts.manrope(fontSize: 22, fontWeight: semibold);
TextStyle h4Text = GoogleFonts.manrope(fontSize: 18, fontWeight: bold);
TextStyle bodyLText = GoogleFonts.manrope(fontSize: 20);
TextStyle bodyMText = GoogleFonts.manrope(fontSize: 18);
TextStyle bodySText = GoogleFonts.manrope(fontSize: 16);
TextStyle bodyXSText = GoogleFonts.manrope(fontSize: 14);

FontWeight light = FontWeight.w300;
FontWeight regular = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semibold = FontWeight.w600;
FontWeight bold = FontWeight.w700;

Map<String, String> languageCodes = {
  'Afrikaans': 'af',
  'Albanian': 'sq',
  'Amharic': 'am',
  'Arabic': 'ar',
  'Armenian': 'hy',
  'Azerbaijani': 'az',
  'Bahasa Indonesia': 'id',
  'Bashkir': 'ba',
  'Basque': 'eu',
  'Belarusian': 'be',
  'Bengali': 'bn',
  'Bosnian': 'bs',
  'Breton': 'br',
  'Bulgarian': 'bg',
  'Burmese': 'my',
  'Catalan': 'ca',
  'Cantonese': 'yue',
  'Chinese': 'zh',
  'Corsican': 'co',
  'Croatian': 'hr',
  'Czech': 'cs',
  'Danish': 'da',
  'Dutch': 'nl',
  'English': 'en',
  'Estonian': 'et',
  'Filipino': 'fil',
  'Finnish': 'fi',
  'French': 'fr',
  'Galician': 'gl',
  'Georgian': 'ka',
  'German': 'de',
  'Greek': 'el',
  'Gujarati': 'gu',
  'Haitian Creole': 'ht',
  'Hausa': 'ha',
  'Hawaiian': 'haw',
  'Hebrew': 'he',
  'Hindi': 'hi',
  'Hungarian': 'hu',
  'Icelandic': 'is',
  'Igbo': 'ig',
  'Irish': 'ga',
  'Italian': 'it',
  'Japanese': 'ja',
  'Javanese': 'jv',
  'Kannada': 'kn',
  'Kazakh': 'kk',
  'Khmer': 'km',
  'Kinyarwanda': 'rw',
  'Korean': 'ko',
  'Kurdish': 'ku',
  'Kyrgyz': 'ky',
  'Lao': 'lo',
  'Latin': 'la',
  'Latvian': 'lv',
  'Lithuanian': 'lt',
  'Luxembourgish': 'lb',
  'Macedonian': 'mk',
  'Malagasy': 'mg',
  'Malay': 'ms',
  'Malayalam': 'ml',
  'Maltese': 'mt',
  'Maori': 'mi',
  'Marathi': 'mr',
  'Mongolian': 'mn',
  'Nepali': 'ne',
  'Norwegian': 'no',
  'Odia (Oriya)': 'or',
  'Pashto': 'ps',
  'Persian': 'fa',
  'Polish': 'pl',
  'Portuguese': 'pt',
  'Punjabi': 'pa',
  'Romanian': 'ro',
  'Russian': 'ru',
  'Samoan': 'sm',
  'Scots Gaelic': 'gd',
  'Serbian': 'sr',
  'Sesotho': 'st',
  'Shona': 'sn',
  'Sindhi': 'sd',
  'Sinhala': 'si',
  'Slovak': 'sk',
  'Slovenian': 'sl',
  'Somali': 'so',
  'Spanish': 'es',
  'Sundanese': 'su',
  'Swahili': 'sw',
  'Swedish': 'sv',
  'Tajik': 'tg',
  'Tamil': 'ta',
  'Tatar': 'tt',
  'Telugu': 'te',
  'Thai': 'th',
  'Tigrinya': 'ti',
  'Turkish': 'tr',
  'Turkmen': 'tk',
  'Ukrainian': 'uk',
  'Urdu': 'ur',
  'Uyghur': 'ug',
  'Uzbek': 'uz',
  'Vietnamese': 'vi',
  'Welsh': 'cy',
  'Western Frisian': 'fy',
  'Xhosa': 'xh',
  'Yiddish': 'yi',
  'Yoruba': 'yo',
  'Zulu': 'zu',
  'Achinese': 'ace',
  'Akan': 'ak',
  'Amis': 'ami',
  'Assamese': 'as',
  'Balinese': 'ban',
  'Bislama': 'bi',
  'Chichewa': 'ny',
  'Dzongkha': 'dz',
  'Faroese': 'fo',
  'Fijian': 'fj',
  'Frisian': 'fy',
  'Gaelic': 'gd',
  'Greenlandic': 'kl',
  'Inuktitut': 'iu',
  'Kikuyu': 'ki',
  'Komi': 'kv',
  'Lingala': 'ln',
  'Marshallese': 'mh',
  'Nauruan': 'na',
  'Palauan': 'pau',
  'Quechua': 'qu',
  'Rundi': 'rn',
  'Sango': 'sg',
  'Sardinian': 'sc',
  'Sichuan Yi': 'ii',
  'Tahitian': 'ty',
  'Tok Pisin': 'tpi',
  'Tonga': 'to',
  'Tuvaluan': 'tvl',
  'Venda': 've',
  'Volapük': 'vo',
  'Wolof': 'wo',
};

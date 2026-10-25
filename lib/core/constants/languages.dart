import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String bcp47;
  final bool isRTL;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.bcp47,
    this.isRTL = false,
  });

  TranslateLanguage get translateLanguage {
    switch (code) {
      case 'ar':
        return TranslateLanguage.arabic;
      case 'en':
        return TranslateLanguage.english;
      case 'es':
        return TranslateLanguage.spanish;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'it':
        return TranslateLanguage.italian;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ru':
        return TranslateLanguage.russian;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'tr':
        return TranslateLanguage.turkish;
      case 'vi':
        return TranslateLanguage.vietnamese;
      case 'th':
        return TranslateLanguage.thai;
      case 'id':
        return TranslateLanguage.indonesian;
      case 'nl':
        return TranslateLanguage.dutch;
      case 'pl':
        return TranslateLanguage.polish;
      case 'uk':
        return TranslateLanguage.ukrainian;
      default:
        return TranslateLanguage.english;
    }
  }
}

const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    flag: '🇸🇦',
    bcp47: 'ar-SA',
    isRTL: true,
  ),
  AppLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    bcp47: 'en-US',
  ),
  AppLanguage(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
    bcp47: 'es-ES',
  ),
  AppLanguage(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
    bcp47: 'fr-FR',
  ),
  AppLanguage(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
    flag: '🇩🇪',
    bcp47: 'de-DE',
  ),
  AppLanguage(
    code: 'it',
    name: 'Italian',
    nativeName: 'Italiano',
    flag: '🇮🇹',
    bcp47: 'it-IT',
  ),
  AppLanguage(
    code: 'pt',
    name: 'Portuguese',
    nativeName: 'Português',
    flag: '🇵🇹',
    bcp47: 'pt-PT',
  ),
  AppLanguage(
    code: 'ru',
    name: 'Russian',
    nativeName: 'Русский',
    flag: '🇷🇺',
    bcp47: 'ru-RU',
  ),
  AppLanguage(
    code: 'zh',
    name: 'Chinese',
    nativeName: '简体中文',
    flag: '🇨🇳',
    bcp47: 'zh-CN',
  ),
  AppLanguage(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    flag: '🇯🇵',
    bcp47: 'ja-JP',
  ),
  AppLanguage(
    code: 'ko',
    name: 'Korean',
    nativeName: '한국어',
    flag: '🇰🇷',
    bcp47: 'ko-KR',
  ),
  AppLanguage(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    flag: '🇮🇳',
    bcp47: 'hi-IN',
  ),
  AppLanguage(
    code: 'tr',
    name: 'Turkish',
    nativeName: 'Türkçe',
    flag: '🇹🇷',
    bcp47: 'tr-TR',
  ),
  AppLanguage(
    code: 'vi',
    name: 'Vietnamese',
    nativeName: 'Tiếng Việt',
    flag: '🇻🇳',
    bcp47: 'vi-VN',
  ),
  AppLanguage(
    code: 'th',
    name: 'Thai',
    nativeName: 'ไทย',
    flag: '🇹🇭',
    bcp47: 'th-TH',
  ),
  AppLanguage(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩',
    bcp47: 'id-ID',
  ),
  AppLanguage(
    code: 'nl',
    name: 'Dutch',
    nativeName: 'Nederlands',
    flag: '🇳🇱',
    bcp47: 'nl-NL',
  ),
  AppLanguage(
    code: 'pl',
    name: 'Polish',
    nativeName: 'Polski',
    flag: '🇵🇱',
    bcp47: 'pl-PL',
  ),
  AppLanguage(
    code: 'uk',
    name: 'Ukrainian',
    nativeName: 'Українська',
    flag: '🇺🇦',
    bcp47: 'uk-UA',
  ),
];

AppLanguage getAppLanguageByCode(String code) {
  final clean = code.toLowerCase().split('-').first.split('_').first;
  return kSupportedLanguages.firstWhere(
    (lang) => lang.code == clean,
    orElse: () => kSupportedLanguages[1], // default English
  );
}

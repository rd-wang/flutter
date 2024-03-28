import 'package:exact/base/local/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ar_AR/ar_ar_translation.dart';
import 'en_US/en_us_translation.dart';
import 'zh_CN/zh_cn_translation.dart';

class RrLocalizationService extends Translations {
  // prevent creating instance
  RrLocalizationService._();

  static RrLocalizationService? _instance;

  static RrLocalizationService getInstance() {
    _instance ??= RrLocalizationService._();
    return _instance!;
  }

  // default language
  // todo change the default language
  static Locale defaultLanguage = supportedLanguages['zh']!;

  // supported languages
  static Map<String, Locale> supportedLanguages = {
    'zh': const Locale('zh', 'CN'),
    'en': const Locale('en', 'US'),
    'ar': const Locale('ar', 'AR'),
  };

  // supported languages fonts family (must be in assets & pubspec yaml) or you can use google fonts
  static Map<String, TextStyle> supportedLanguagesFontsFamilies = {
    // todo add your English font families (add to assets/fonts, pubspec and name it here) default is poppins for english and cairo for arabic
    "zh": const TextStyle(),
    'en': const TextStyle(fontFamily: 'Poppins'),
    'ar': const TextStyle(fontFamily: 'Cairo'),
  };

  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': zhCN,
        'en_US': enUs,
        'ar_AR': arAR,
      };

  /// check if the language is supported
  static isLanguageSupported(String languageCode) => supportedLanguages.keys.contains(languageCode);

  /// update app language by code language for example (en,ar..etc)
  static updateLanguage(String languageCode) async {
    // check if the language is supported
    if (!isLanguageSupported(languageCode)) return;
    // update current language in shared pref
    await RrSharedPref.setCurrentLanguage(languageCode);
    if (!Get.testMode) {
      Get.updateLocale(supportedLanguages[languageCode]!);
    }
  }

  /// check if the language is english
  static bool isItEnglish() => RrSharedPref.getCurrentLocal().languageCode.toLowerCase().contains('en');

  /// get current locale
  static Locale getCurrentLocal() => RrSharedPref.getCurrentLocal();
}

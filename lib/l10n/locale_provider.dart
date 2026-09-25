import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LocaleProvider extends ChangeNotifier {
  String _localeStr = 'en';

  String get localeStr => _localeStr;
  Locale get locale => Locale(_localeStr);

  LocaleProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    _localeStr = ['en', 'th', 'zh'].contains(saved) ? saved! : 'en';
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (['th', 'zh', 'en'].contains(languageCode)) {
      _localeStr = languageCode;
      notifyListeners();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
    }
  }

  String tr(String key, {Map<String, String>? args}) {
    final langData = AppTranslations.locale[_localeStr] ?? AppTranslations.locale['en']!;
    String res = langData[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v);
      });
    }
    return res;
  }
}

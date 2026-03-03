import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LocaleProvider extends ChangeNotifier {
  String _localeStr = 'th';

  String get localeStr => _localeStr;
  Locale get locale => Locale(_localeStr);

  LocaleProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _localeStr = prefs.getString('language') ?? 'th';
    notifyListeners();
  }

  void setLocale(String languageCode) async {
    if (['th', 'zh', 'en'].contains(languageCode)) {
      _localeStr = languageCode;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      notifyListeners();
    }
  }

  String tr(String key, {Map<String, String>? args}) {
    final langData = AppTranslations.locale[_localeStr] ?? AppTranslations.locale['th']!;
    String res = langData[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v);
      });
    }
    return res;
  }
}

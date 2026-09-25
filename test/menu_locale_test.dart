import 'package:cashier_trae/models/menu_item.dart';
import 'package:cashier_trae/l10n/locale_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first launch starts in English', () {
    SharedPreferences.setMockInitialValues({});
    final locale = LocaleProvider();
    expect(locale.localeStr, 'en');
    expect(locale.tr('app_title'), 'Cashier');
  });

  test('product names follow selected language', () {
    const item = MenuItem(
      nameEn: 'Apple',
      nameTh: 'แอปเปิล',
      nameCn: '苹果',
      price: 10,
    );
    expect(item.nameFor('en'), 'Apple');
    expect(item.nameFor('th'), 'แอปเปิล');
    expect(item.nameFor('zh'), '苹果');
  });

  test('legacy Thai-only products remain visible after migration', () {
    final item = MenuItem.fromMap({
      'id': 1,
      'name_th': 'แอปเปิล',
      'name_cn': '',
      'price': 10,
      'is_by_weight': 1,
    });
    expect(item.nameFor('en'), 'แอปเปิล');
    expect(item.toMap()['name_en'], '');
  });
}

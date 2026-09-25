import 'package:cashier_trae/models/menu_item.dart';
import 'package:cashier_trae/services/ai_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ranks closest trained product and excludes quick weighing item', () {
    final apple = MenuItem(id: 11, nameEn: 'Apple', price: 10);
    final pear = MenuItem(id: 12, nameEn: 'Pear', price: 12);
    final matches = AiRecognitionService.rank(
      [1, 0, 0],
      [(11, [0.8, 0.2, 0]), (12, [0.1, 0.9, 0]), (-1, [1, 0, 0])],
      [MenuItem.quickWeigh, apple, pear],
    );
    expect(matches.map((match) => match.item.id), [11, 12]);
    expect(matches.first.similarity, greaterThan(matches.last.similarity));
  });

  test('ignores invalid, zero, and different-length vectors', () {
    final item = MenuItem(id: 1, nameEn: 'Apple', price: 10);
    expect(AiRecognitionService.rank([1, 0], [(1, [0, 0])], [item]), isEmpty);
    expect(AiRecognitionService.rank([1, 0], [(1, [1])], [item]), isEmpty);
    expect(AiRecognitionService.cosine([1, 0], [double.nan, 0]), isNull);
  });
}

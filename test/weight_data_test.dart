import 'package:flutter_test/flutter_test.dart';
import 'package:cashier_trae/services/weight_service.dart';

void main() {
  test('only stable, valid positive kilograms can be sold', () {
    WeightData frame(double kg, {bool stable = true, bool valid = true}) =>
        WeightData(raw: '', kg: kg, stable: stable, valid: valid);

    expect(frame(1.25).canSell, isTrue);
    expect(frame(1.25, stable: false).canSell, isFalse);
    expect(frame(1.25, valid: false).canSell, isFalse);
    expect(frame(0).canSell, isFalse);
    expect(frame(-1).canSell, isFalse);
    expect(frame(double.nan).canSell, isFalse);
    expect(frame(double.infinity).canSell, isFalse);
  });

  test('Android weight event values are parsed', () {
    final frame = WeightData.fromMap({
      'raw': 'frame', 'kg': 0.75, 'stable': true, 'valid': true,
    });
    expect(frame.kg, 0.75);
    expect(frame.canSell, isTrue);
  });
}

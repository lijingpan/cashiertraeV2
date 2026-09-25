import 'package:cashier_trae/models/cart_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weighed sale rounds a half cent up', () {
    expect(
      CartItem.saleSubtotal(byWeight: true, quantity: 0.695, price: 1),
      0.70,
    );
  });

  test('piece sale uses integer quantity and cent price', () {
    expect(
      CartItem.saleSubtotal(byWeight: false, quantity: 2, price: 1.99),
      3.98,
    );
  });
}

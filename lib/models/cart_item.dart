import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  final double weight;  // kg（称重商品），或件数（固定价格商品）
  final double subtotal;

  const CartItem({
    required this.menuItem,
    required this.weight,
    required this.subtotal,
  });

  /// 称重精确到克、单价精确到分；每行金额按分四舍五入。
  static double saleSubtotal({
    required bool byWeight,
    required double quantity,
    required double price,
  }) {
    final priceCents = (price * 100).round();
    if (byWeight) {
      final grams = (quantity * 1000).round();
      return ((grams * priceCents + 500) ~/ 1000) / 100;
    }
    return quantity.round() * priceCents / 100;
  }

  String get weightLabel => menuItem.isByWeight
      ? '${weight.toStringAsFixed(3)} kg'
      : 'x${weight.toStringAsFixed(0)}';

  /// 转为传给 Android 打印的 Map
  Map<String, dynamic> toPrintMap() => {
        'name': menuItem.nameTh,
        'weight': weight,
        'price': menuItem.price,
        'subtotal': subtotal,
        'byWeight': menuItem.isByWeight,
      };
}

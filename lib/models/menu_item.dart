class MenuItem {
  final int? id;
  final String nameTh;   // 泰文名（主显示）
  final String nameCn;   // 中文名（备注）
  final double price;    // 单价：按重量计价时为 ฿/kg，固定价格时为件价
  final bool isByWeight; // true = 称重计价, false = 固定单价

  const MenuItem({
    this.id,
    required this.nameTh,
    this.nameCn = '',
    required this.price,
    this.isByWeight = true,
  });

  MenuItem copyWith({
    int? id,
    String? nameTh,
    String? nameCn,
    double? price,
    bool? isByWeight,
  }) {
    return MenuItem(
      id: id ?? this.id,
      nameTh: nameTh ?? this.nameTh,
      nameCn: nameCn ?? this.nameCn,
      price: price ?? this.price,
      isByWeight: isByWeight ?? this.isByWeight,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name_th': nameTh,
        'name_cn': nameCn,
        'price': price,
        'is_by_weight': isByWeight ? 1 : 0,
      };

  factory MenuItem.fromMap(Map<String, dynamic> m) => MenuItem(
        id: m['id'] as int?,
        nameTh: m['name_th'] as String,
        nameCn: (m['name_cn'] as String?) ?? '',
        price: (m['price'] as num).toDouble(),
        isByWeight: (m['is_by_weight'] as int) == 1,
      );

  /// 显示名：优先泰文，中文作为辅助
  String get displayName => nameTh;
  String get subName => nameCn;
}

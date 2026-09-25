class MenuItem {
  final int? id;
  final String nameEn;
  final String nameTh;
  final String nameCn;
  final double price;    // 单价：按重量计价时为 ฿/kg，固定价格时为件价
  final bool isByWeight; // true = 称重计价, false = 固定单价

  const MenuItem({
    this.id,
    this.nameEn = '',
    this.nameTh = '',
    this.nameCn = '',
    required this.price,
    this.isByWeight = true,
  });

  MenuItem copyWith({
    int? id,
    String? nameEn,
    String? nameTh,
    String? nameCn,
    double? price,
    bool? isByWeight,
  }) {
    return MenuItem(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameTh: nameTh ?? this.nameTh,
      nameCn: nameCn ?? this.nameCn,
      price: price ?? this.price,
      isByWeight: isByWeight ?? this.isByWeight,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name_en': nameEn,
        'name_th': nameTh,
        'name_cn': nameCn,
        'price': price,
        'is_by_weight': isByWeight ? 1 : 0,
      };

  factory MenuItem.fromMap(Map<String, dynamic> m) => MenuItem(
        id: m['id'] as int?,
        nameEn: (m['name_en'] as String?) ?? '',
        nameTh: (m['name_th'] as String?) ?? '',
        nameCn: (m['name_cn'] as String?) ?? '',
        price: (m['price'] as num).toDouble(),
        isByWeight: (m['is_by_weight'] as int) == 1,
      );

  /// 优先使用所选语言；旧商品缺少译名时回退到已有名称。
  String nameFor(String language) {
    final names = switch (language) {
      'th' => [nameTh, nameEn, nameCn],
      'zh' => [nameCn, nameEn, nameTh],
      _ => [nameEn, nameTh, nameCn],
    };
    return names.firstWhere((name) => name.trim().isNotEmpty, orElse: () => '');
  }
}

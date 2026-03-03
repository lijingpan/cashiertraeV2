import 'package:flutter/services.dart';
import '../models/cart_item.dart';

/// 封装 Android 侧 PrintChannel，负责打印收据。
class PrintService {
  static final PrintService _instance = PrintService._();
  factory PrintService() => _instance;
  PrintService._();

  static const _method = MethodChannel('cashier/print');

  bool _connected = false;
  bool get isConnected => _connected;

  /// 连接打印机（USB）
  Future<bool> connect() async {
    try {
      final result = await _method.invokeMethod<bool>('openPort');
      _connected = result ?? false;
      return _connected;
    } on PlatformException {
      _connected = false;
      return false;
    }
  }

  /// 断开打印机
  Future<void> disconnect() async {
    await _method.invokeMethod('closePort');
    _connected = false;
  }

  /// 打印收据
  /// [shopName] 店名（泰文），[items] 购物车，[total] 总金额
  Future<bool> printTicket({
    required String shopName,
    required List<CartItem> items,
    required double total,
  }) async {
    try {
      // 如果未连接，先尝试连接
      if (!_connected) {
        final ok = await connect();
        if (!ok) return false;
      }

      await _method.invokeMethod('printTicket', {
        'shopName': shopName,
        'items': items.map((e) => e.toPrintMap()).toList(),
        'total': total,
      });
      return true;
    } on PlatformException {
      _connected = false;
      return false;
    }
  }
}

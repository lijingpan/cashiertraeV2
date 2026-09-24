import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 封装 Android 侧 WeightChannel，提供称重数据流。
class WeightService {
  static final WeightService _instance = WeightService._();
  factory WeightService() => _instance;
  WeightService._();

  static const _method = MethodChannel('cashier/weight');
  static const _event = EventChannel('cashier/weight/events');

  Stream<WeightData>? _stream;

  /// 实时重量数据流（由 Android 串口推送）
  Stream<WeightData> get weightStream {
    _stream ??= _event
        .receiveBroadcastStream()
        .map((e) => WeightData.fromMap(Map<String, dynamic>.from(e as Map)));
    return _stream!;
  }

  /// 打开串口，优先读取 SharedPreferences 中保存的设置。
  Future<bool> open({String? path, int? rate}) async {
    final prefs = await SharedPreferences.getInstance();
    final p = path ?? prefs.getString('serial_path') ?? '/dev/ttyS4';
    final r = rate ?? prefs.getInt('serial_rate') ?? 9600;
    try {
      final result = await _method.invokeMethod<bool>('open', {'path': p, 'rate': r});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 关闭串口
  Future<void> close() async {
    await _method.invokeMethod('close');
  }

  /// 去皮（置零）
  Future<bool> tare() async {
    final result = await _method.invokeMethod<bool>('tare');
    return result ?? false;
  }

  /// 归零
  Future<bool> zero() async {
    final result = await _method.invokeMethod<bool>('zero');
    return result ?? false;
  }

  /// 主动请求一次重量
  Future<bool> requestWeight() async {
    final result = await _method.invokeMethod<bool>('requestWeight');
    return result ?? false;
  }
}

class WeightData {
  final String raw;    // 原始字符串（用于调试）
  final double kg;     // 净重 kg
  final bool stable;   // 是否稳定
  final bool valid;    // 是否有效数值

  const WeightData({
    required this.raw,
    required this.kg,
    required this.stable,
    required this.valid,
  });

  bool get canSell => valid && stable && kg.isFinite && kg > 0;

  factory WeightData.fromMap(Map<String, dynamic> m) {
    double tempKg = 0.0;
    if (m['kg'] != null) {
      tempKg = (m['kg'] as num).toDouble();
    } else if (m['netWeight'] != null) {
      tempKg = (m['netWeight'] as num).toDouble();
    }
    
    return WeightData(
      raw: m['raw'] as String? ?? '0',
      kg: tempKg,
      stable: m['stable'] as bool? ?? m['isStable'] as bool? ?? false,
      valid: m['valid'] as bool? ?? m['isStable'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'WeightData(kg=$kg, stable=$stable, valid=$valid)';
}

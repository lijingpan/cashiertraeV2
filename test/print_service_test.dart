import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashier_trae/models/cart_item.dart';
import 'package:cashier_trae/services/print_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cashier/print');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    await PrintService().disconnect();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('failed device print keeps result false', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'openPort') return true;
      if (call.method == 'printTicket') return false;
      return true;
    });

    final result = await PrintService().printTicket(
      shopName: 'Shop', items: <CartItem>[], total: 0,
    );
    expect(result, isFalse);
  });

  test('successful device print returns true', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'openPort') return true;
      if (call.method == 'printTicket') return true;
      return true;
    });

    final result = await PrintService().printTicket(
      shopName: 'Shop', items: <CartItem>[], total: 0,
    );
    expect(result, isTrue);
  });
}

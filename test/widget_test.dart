import 'package:flutter_test/flutter_test.dart';
import 'package:cashier_trae/main.dart';

void main() {
  testWidgets('CashierApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CashierApp());
    expect(find.byType(CashierApp), findsOneWidget);
  });
}

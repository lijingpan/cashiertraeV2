import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/cashier_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制横屏（收银台常见使用方式）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const CashierApp());
}

class CashierApp extends StatelessWidget {
  const CashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '收银台',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
      ),
      home: const CashierScreen(),
    );
  }
}

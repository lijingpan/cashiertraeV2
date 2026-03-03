import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/cashier_screen.dart';
import 'l10n/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 強制横屏 (Force landscape)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const CashierApp(),
    ),
  );
}

class CashierApp extends StatelessWidget {
  const CashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: provider.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0077B6),
              primary: const Color(0xFF0077B6),
              secondary: const Color(0xFF00B4D8),
              surface: Colors.white,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0077B6),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 50
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
            ),
          ),
          locale: provider.locale,
          home: const CashierScreen(),
        );
      },
    );
  }
}

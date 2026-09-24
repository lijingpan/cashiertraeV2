import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weight_service.dart';
import '../l10n/locale_provider.dart';
import '../utils/top_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pathCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  bool _printEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _pathCtrl.text = prefs.getString('serial_path') ?? '/dev/ttyS4';
    _rateCtrl.text = (prefs.getInt('serial_rate') ?? 9600).toString();
    _shopCtrl.text = prefs.getString('shop_name') ?? 'ร้านอาหาร';
    setState(() => _printEnabled = prefs.getBool('print_enabled') ?? true);
  }

  Future<void> _save(LocaleProvider lp) async {
    final path = _pathCtrl.text.trim();
    final rate = int.tryParse(_rateCtrl.text.trim());
    if (path.isEmpty || rate == null || rate <= 0) {
      TopToast.show(context, lp.tr('invalid_serial_settings'), type: ToastType.error);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serial_path', path);
    await prefs.setInt('serial_rate', rate);
    await prefs.setString('shop_name', _shopCtrl.text.trim());
    await prefs.setBool('print_enabled', _printEnabled);
    if (!mounted) return;
    TopToast.show(context, lp.tr('settings_saved'), type: ToastType.success);
  }

  Future<void> _testScale(LocaleProvider lp) async {
    final path = _pathCtrl.text.trim();
    final rate = int.tryParse(_rateCtrl.text.trim());
    if (path.isEmpty || rate == null || rate <= 0) {
      TopToast.show(context, lp.tr('invalid_serial_settings'), type: ToastType.error);
      return;
    }
    final ok = await WeightService().open(path: path, rate: rate);
    if (!mounted) return;
    TopToast.show(
      context,
      ok ? lp.tr('serial_success', args: {'path': path}) : lp.tr('serial_fail'),
      type: ok ? ToastType.success : ToastType.error,
    );
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _rateCtrl.dispose();
    _shopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(lp.tr('settings'), style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Section(title: lp.tr('shop_info'), children: [
                TextField(
                  controller: _shopCtrl,
                  decoration: InputDecoration(
                    labelText: lp.tr('shop_name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _Section(title: lp.tr('printer_settings'), children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lp.tr('print_enabled')),
                  subtitle: Text(lp.tr('print_enabled_hint')),
                  value: _printEnabled,
                  onChanged: (value) => setState(() => _printEnabled = value),
                ),
              ]),
              const SizedBox(height: 24),
              _Section(title: lp.tr('serial_setting'), children: [
                TextField(
                  controller: _pathCtrl,
                  decoration: InputDecoration(
                    labelText: lp.tr('serial_path'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: lp.tr('baud_rate'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cable_rounded, size: 24),
                  label: Text(lp.tr('test_connection'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _testScale(lp),
                ),
              ]),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.save_rounded, size: 24),
                label: Text(lp.tr('save_settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _save(lp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

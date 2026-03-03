import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weight_service.dart';

/// 串口 & 打印机配置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pathCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _pathCtrl.text = prefs.getString('serial_path') ?? '/dev/ttyS3';
    _rateCtrl.text = (prefs.getInt('serial_rate') ?? 9600).toString();
    _shopCtrl.text = prefs.getString('shop_name') ?? 'ร้านอาหาร';
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serial_path', _pathCtrl.text.trim());
    await prefs.setInt('serial_rate', int.tryParse(_rateCtrl.text.trim()) ?? 9600);
    await prefs.setString('shop_name', _shopCtrl.text.trim());
    setState(() {});  // 触发重绘显示保存反馈
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存，重新连接称重后生效')));
  }

  Future<void> _testScale() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('serial_path') ?? '/dev/ttyS3';
    final rate = prefs.getInt('serial_rate') ?? 9600;
    final ok = await WeightService().open(path: path, rate: rate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '串口连接成功: $path' : '串口连接失败')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: '店铺信息', children: [
            TextField(
              controller: _shopCtrl,
              decoration: const InputDecoration(
                labelText: '店名（泰文，打印在票头）',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: '称重秤 — 串口设置', children: [
            TextField(
              controller: _pathCtrl,
              decoration: const InputDecoration(
                labelText: '串口路径 (如 /dev/ttyS3)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '波特率 (如 9600)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.cable),
              label: const Text('测试串口连接'),
              onPressed: _testScale,
            ),
          ]),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1976D2))),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

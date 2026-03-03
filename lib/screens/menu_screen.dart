import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/db_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _db = DbService();
  List<MenuItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getMenuItems();
    setState(() => _items = items);
  }

  Future<void> _showDialog({MenuItem? editing}) async {
    final nameThCtrl = TextEditingController(text: editing?.nameTh ?? '');
    final nameCnCtrl = TextEditingController(text: editing?.nameCn ?? '');
    final priceCtrl = TextEditingController(
        text: editing != null ? editing.price.toStringAsFixed(2) : '');
    bool isByWeight = editing?.isByWeight ?? true;

    final saved = await showDialog<MenuItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(editing == null ? '添加商品' : '编辑商品'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameThCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ (泰文名) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCnCtrl,
                decoration: const InputDecoration(
                  labelText: '中文名（选填）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isByWeight ? '单价 (฿/kg) *' : '售价 (฿/件) *',
                  border: const OutlineInputBorder(),
                  prefixText: '฿ ',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('称重计价'),
                subtitle: Text(isByWeight ? '按公斤计算价格' : '固定件价'),
                value: isByWeight,
                onChanged: (v) => setDlg(() => isByWeight = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text('保存'),
              onPressed: () {
                final nameTh = nameThCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim());
                if (nameTh.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('请输入泰文名')));
                  return;
                }
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('请输入有效价格')));
                  return;
                }
                Navigator.pop(ctx, MenuItem(
                  id: editing?.id,
                  nameTh: nameTh,
                  nameCn: nameCnCtrl.text.trim(),
                  price: price,
                  isByWeight: isByWeight,
                ));
              },
            ),
          ],
        ),
      ),
    );

    if (saved == null) return;
    if (editing == null) {
      await _db.insertMenuItem(saved);
    } else {
      await _db.updateMenuItem(saved);
    }
    await _load();
  }

  Future<void> _delete(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 "${item.nameTh}" ?'),
        actions: [
          TextButton(child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(
            child: const Text('删除', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      await _db.deleteMenuItem(item.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('菜单管理'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _items.isEmpty
          ? const Center(child: Text('暂无商品，点击 + 添加', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = _items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isByWeight
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFFFF3E0),
                    child: Icon(
                      item.isByWeight ? Icons.scale : Icons.fastfood,
                      color: item.isByWeight ? Colors.blue : Colors.orange,
                    ),
                  ),
                  title: Text(item.nameTh,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${item.nameCn}  •  ${item.isByWeight ? "฿/kg" : "฿/件"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '${item.price.toStringAsFixed(2)} ฿',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showDialog(editing: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _delete(item),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showDialog(),
      ),
    );
  }
}

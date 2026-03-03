import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/db_service.dart';
import '../l10n/locale_provider.dart';

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

  Future<void> _showDialog(LocaleProvider lp, {MenuItem? editing}) async {
    final nameThCtrl = TextEditingController(text: editing?.nameTh ?? '');
    final nameCnCtrl = TextEditingController(text: editing?.nameCn ?? '');
    final priceCtrl = TextEditingController(
        text: editing != null ? editing.price.toStringAsFixed(2) : '');
    bool isByWeight = editing?.isByWeight ?? true;

    final saved = await showDialog<MenuItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(editing == null ? lp.tr('add_product') : lp.tr('edit_product'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameThCtrl,
                decoration: InputDecoration(
                  labelText: lp.tr('product_name_th'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC)
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCnCtrl,
                decoration: InputDecoration(
                  labelText: lp.tr('product_name_cn'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC)
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isByWeight ? lp.tr('price_kg') : lp.tr('price_pc'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixText: '฿ ',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC)
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(lp.tr('weighing_scale_pricing'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isByWeight ? lp.tr('calc_per_kg') : lp.tr('fixed_piece_price'), style: const TextStyle(fontSize: 12)),
                  value: isByWeight,
                  onChanged: (v) => setDlg(() => isByWeight = v),
                  activeThumbColor: const Color(0xFF0284C7),
                ),
              ),
            ]),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              child: Text(lp.tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(lp.tr('save')),
              onPressed: () {
                final nameTh = nameThCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim());
                if (nameTh.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(lp.tr('enter_th_name'))));
                  return;
                }
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(lp.tr('enter_valid_price'))));
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

  Future<void> _delete(LocaleProvider lp, MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lp.tr('delete_info'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(lp.tr('delete_confirm', args: {'name': item.nameTh})),
        actions: [
          TextButton(child: Text(lp.tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))), onPressed: () => Navigator.pop(ctx, false)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text(lp.tr('delete')),
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
    final lp = Provider.of<LocaleProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(lp.tr('menu_manage'), style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _items.isEmpty
          ? Center(child: Text(lp.tr('no_product'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = _items[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.isByWeight ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.isByWeight ? Icons.scale_rounded : Icons.fastfood_rounded,
                        color: item.isByWeight ? const Color(0xFF0EA5E9) : const Color(0xFFD97706),
                      ),
                    ),
                    title: Text(item.nameTh, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                      '${item.nameCn.isNotEmpty ? '${item.nameCn} • ' : ''}${item.isByWeight ? lp.tr('price_kg') : lp.tr('price_pc')}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        '฿ ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 22, color: Color(0xFF64748B)),
                        onPressed: () => _showDialog(lp, editing: item),
                        splashRadius: 24,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFFEF4444)),
                        onPressed: () => _delete(lp, item),
                        splashRadius: 24,
                      ),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(lp.tr('add_product'), style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showDialog(lp),
      ),
    );
  }
}

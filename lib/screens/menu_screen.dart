import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/db_service.dart';
import '../l10n/locale_provider.dart';
import '../utils/top_toast.dart';

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
    final nameEnCtrl = TextEditingController(text: editing?.nameEn ?? '');
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
          title: Row(
            children: [
              Icon(editing == null ? Icons.add_circle_outline : Icons.edit_outlined, color: const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(editing == null ? lp.tr('add_product') : lp.tr('edit_product'), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(lp.tr('product_name_en'), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      hintText: lp.tr('enter_en_name'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(lp.tr('product_name_th'), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameThCtrl,
                    decoration: InputDecoration(
                      hintText: lp.tr('product_name_th'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(lp.tr('product_name_cn'), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCnCtrl,
                    decoration: InputDecoration(
                      hintText: lp.tr('product_name_cn'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isByWeight ? lp.tr('price_kg') : lp.tr('price_pc'), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixText: '฿ ',
                                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(' ', style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isByWeight ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isByWeight ? Colors.transparent : const Color(0xFFFFEDD5)),
                              ),
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.only(left: 12, right: 4),
                                title: Text(lp.tr('weighing_scale_pricing'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                value: isByWeight,
                                onChanged: (v) => setDlg(() => isByWeight = v),
                                activeThumbColor: const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          actions: [
            TextButton(
              child: Text(lp.tr('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(lp.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final nameEn = nameEnCtrl.text.trim();
                final nameTh = nameThCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim());
                if (nameEn.isEmpty) {
                  TopToast.show(ctx, lp.tr('enter_en_name'), type: ToastType.error);
                  return;
                }
                if (price == null || price < 0) {
                  TopToast.show(ctx, lp.tr('enter_valid_price'), type: ToastType.error);
                  return;
                }
                Navigator.pop(ctx, MenuItem(
                  id: editing?.id,
                  nameEn: nameEn,
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
    if (!mounted) return;
    TopToast.show(context, lp.tr('save_success'), type: ToastType.success);
    await _load();
  }

  Future<void> _delete(LocaleProvider lp, MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lp.tr('delete_info'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(lp.tr('delete_confirm', args: {'name': item.nameFor(lp.localeStr)})),
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
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: const Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  Text(lp.tr('no_product'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _showDialog(lp, editing: item),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.isByWeight 
                                    ? [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)]
                                    : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.isByWeight ? Icons.scale_rounded : Icons.fastfood_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nameFor(lp.localeStr),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                              child: Text(item.isByWeight ? lp.tr('price_kg') : lp.tr('price_pc'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 130,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    const Text('฿', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                    const SizedBox(width: 2),
                                    Text(item.price.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ActionButton(icon: Icons.edit_rounded, color: const Color(0xFF64748B), onTap: () => _showDialog(lp, editing: item)),
                                const SizedBox(width: 8),
                                _ActionButton(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444), onTap: () => _delete(lp, item)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(lp.tr('add_product'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        onPressed: () => _showDialog(lp),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

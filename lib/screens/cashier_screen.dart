import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../services/db_service.dart';
import '../services/weight_service.dart';
import '../services/print_service.dart';
import '../l10n/locale_provider.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _db = DbService();
  final _weight = WeightService();
  final _print = PrintService();

  List<MenuItem> _menuItems = [];
  final List<CartItem> _cart = [];

  double _currentKg = 0.0;
  bool _weightStable = false;
  bool _weightValid = false;
  bool _scaleConnected = false;
  StreamSubscription<WeightData>? _weightSub;

  MenuItem? _selectedItem;
  bool _printerConnected = false;
  int _fixedQty = 1;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _connectScale();
    _connectPrinter();
  }

  @override
  void dispose() {
    _weightSub?.cancel();
    _weight.close();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final items = await _db.getMenuItems();
    setState(() => _menuItems = items);
  }

  Future<void> _connectScale() async {
    final ok = await _weight.open();
    if (!mounted) return;
    setState(() => _scaleConnected = ok);
    if (ok) {
      _weightSub = _weight.weightStream.listen((data) {
        setState(() {
          _currentKg = data.kg;
          _weightStable = data.stable;
          _weightValid = data.kg > 0;
        });
      });
    }
  }

  Future<void> _connectPrinter() async {
    final ok = await _print.connect();
    if (!mounted) return;
    setState(() => _printerConnected = ok);
  }

  void _selectMenuItem(MenuItem item) {
    setState(() {
      _selectedItem = item;
      _fixedQty = 1;
    });
  }

  void _addToCart(LocaleProvider lp) {
    if (_selectedItem == null) return;
    final item = _selectedItem!;

    double qty;
    double subtotal;

    if (item.isByWeight) {
      if (!_weightValid || _currentKg <= 0) {
        _showSnack(lp.tr('pls_put_on_scale'));
        return;
      }
      qty = _currentKg;
      subtotal = qty * item.price;
    } else {
      qty = _fixedQty.toDouble();
      subtotal = qty * item.price;
    }

    setState(() {
      _cart.add(CartItem(menuItem: item, weight: qty, subtotal: subtotal));
      _selectedItem = null;
    });
  }

  void _removeCartItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedItem = null;
    });
  }

  double get _total => _cart.fold(0.0, (sum, e) => sum + e.subtotal);

  Future<void> _printReceipt(LocaleProvider lp) async {
    if (_cart.isEmpty) {
      _showSnack(lp.tr('cart_empty'));
      return;
    }
    _showSnack(lp.tr('printing'));
    
    final prefs = await SharedPreferences.getInstance();
    final shopName = prefs.getString('shop_name') ?? 'ร้านอาหาร';

    final ok = await _print.printTicket(
      shopName: shopName,
      items: _cart,
      total: _total,
    );
    if (!mounted) return;
    setState(() => _printerConnected = ok || _printerConnected);
    _showSnack(lp.tr(ok ? 'print_success' : 'print_fail'));
    if (ok) _clearCart();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 50
      appBar: _buildAppBar(lp),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 13, child: _buildMenuPanel(lp)),
            const SizedBox(width: 12),
            Expanded(flex: 9, child: _buildRightPanel(lp)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(LocaleProvider lp) {
    return AppBar(
      title: Text(lp.tr('app_title'), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A), // Slate 900
      actions: [
        _StatusChip(
          icon: Icons.scale_rounded,
          label: lp.tr('scale'),
          connected: _scaleConnected,
          onTap: _connectScale,
        ),
        const SizedBox(width: 8),
        _StatusChip(
          icon: Icons.print_rounded,
          label: lp.tr('printer'),
          connected: _printerConnected,
          onTap: _connectPrinter,
        ),
        const SizedBox(width: 16),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: lp.localeStr,
              items: [
                DropdownMenuItem(value: 'th', child: Text(lp.tr('lang_th'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'zh', child: Text(lp.tr('lang_zh'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'en', child: Text(lp.tr('lang_en'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              ],
              onChanged: (v) {
                if (v != null) lp.setLocale(v);
              },
              icon: const Icon(Icons.language, size: 18, color: Color(0xFF64748B)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.restaurant_menu_rounded),
          tooltip: lp.tr('menu_manage'),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen()));
            _loadMenu();
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: lp.tr('settings'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMenuPanel(LocaleProvider lp) {
    if (_menuItems.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fastfood_rounded, size: 72, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(lp.tr('empty_menu'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (_, i) => _MenuCard(
            item: _menuItems[i],
            selected: _selectedItem?.id == _menuItems[i].id,
            onTap: () => _selectMenuItem(_menuItems[i]),
            lp: lp,
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(LocaleProvider lp) {
    return Column(
      children: [
        _buildWeightSection(lp),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Expanded(child: _buildCartList(lp)),
                _buildBottomBar(lp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection(LocaleProvider lp) {
    final hasSelected = _selectedItem != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelected) ...[
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                child: Icon(_selectedItem!.isByWeight ? Icons.scale_rounded : Icons.fastfood_rounded, size: 20, color: const Color(0xFF0284C7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.localeStr == 'zh' && _selectedItem!.nameCn.isNotEmpty ? _selectedItem!.nameCn : _selectedItem!.nameTh,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedItem!.isByWeight
                          ? '${_selectedItem!.price.toStringAsFixed(2)} ${lp.tr('price_kg')}'
                          : '${_selectedItem!.price.toStringAsFixed(2)} ${lp.tr('price_pc')}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (hasSelected && _selectedItem!.isByWeight) ...[
            _WeightDisplay(kg: _currentKg, valid: _weightValid, stable: _weightStable, lp: lp),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.exposure_zero_rounded),
                  label: Text(lp.tr('tare')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _weight.tare(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(lp.tr('add_to_cart'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald 500
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _addToCart(lp),
                ),
              ),
            ]),
          ],
          if (hasSelected && !_selectedItem!.isByWeight) ...[
            Row(children: [
              Text(lp.tr('qty'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const Spacer(),
              _QtyButton(icon: Icons.remove_rounded, onPressed: () => setState(() => _fixedQty = (_fixedQty - 1).clamp(1, 99))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_fixedQty', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
              _QtyButton(icon: Icons.add_rounded, onPressed: () => setState(() => _fixedQty = (_fixedQty + 1).clamp(1, 99))),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(lp.tr('add_to_cart'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _addToCart(lp),
              ),
            )
          ],
          if (!hasSelected)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(lp.tr('pls_select_from_left'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartList(LocaleProvider lp) {
    if (_cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_basket_outlined, size: 60, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Text(lp.tr('cart_empty'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w500)),
          ]
        )
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _cart.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) {
        final item = _cart[i];
        final isZh = lp.localeStr == 'zh' && item.menuItem.nameCn.isNotEmpty;
        final name = isZh ? item.menuItem.nameCn : item.menuItem.nameTh;
        final unit = item.menuItem.isByWeight ? lp.tr('unit_kg') : lp.tr('unit_pc');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(
                      '${item.weight.toStringAsFixed(3)} $unit × ${item.menuItem.price.toStringAsFixed(2)} ฿',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Text(
                '฿ ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () => _removeCartItem(i),
                color: const Color(0xFFEF4444), // Red 500
                visualDensity: VisualDensity.compact,
                splashRadius: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(LocaleProvider lp) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lp.tr('total').toUpperCase(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                '฿ ${_total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)), // Sky 600
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded),
                label: Text(lp.tr('clear')),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _cart.isEmpty ? null : _clearCart,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.receipt_long_rounded, size: 22),
                  label: Text(lp.tr('print_ticket'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9), // Sky 500
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _cart.isEmpty ? null : () => _printReceipt(lp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  final LocaleProvider lp;

  const _MenuCard({required this.item, required this.selected, required this.onTap, required this.lp});

  @override
  Widget build(BuildContext context) {
    final isZh = lp.localeStr == 'zh' && item.nameCn.isNotEmpty;
    final primaryName = isZh ? item.nameCn : item.nameTh;
    final secondaryName = isZh ? item.nameTh : (item.nameCn.isNotEmpty ? item.nameCn : '');
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x660284C7), blurRadius: 12, offset: Offset(0, 6))]
              : [const BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.isByWeight ? Icons.scale_rounded : Icons.fastfood_rounded,
                size: 32,
                color: selected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const Spacer(),
              Text(
                primaryName,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF1E293B)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (secondaryName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondaryName,
                  style: TextStyle(fontSize: 11, color: selected ? const Color(0xBBFFFFFF) : const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x33FFFFFF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  item.isByWeight
                      ? '${item.price.toStringAsFixed(2)} ${lp.tr('price_kg')}'
                      : '${item.price.toStringAsFixed(2)} ${lp.tr('price_pc')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightDisplay extends StatelessWidget {
  final double kg;
  final bool valid;
  final bool stable;
  final LocaleProvider lp;

  const _WeightDisplay({required this.kg, required this.valid, required this.stable, required this.lp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), // Green 100 or Slate 100
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: valid ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.scale_rounded, color: valid ? const Color(0xFF16A34A) : const Color(0xFF94A3B8), size: 32),
          const SizedBox(width: 16),
          Text(
            '${kg.toStringAsFixed(3)} kg',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: valid ? const Color(0xFF166534) : const Color(0xFF64748B),
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
          if (valid && stable) ...[
            const SizedBox(width: 12),
            Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
          ]
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool connected;
  final VoidCallback onTap;

  const _StatusChip({required this.icon, required this.label, required this.connected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: connected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: connected ? const Color(0xFFB1F2C2) : const Color(0xFFFECACA))
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: connected ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: connected ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
        ]),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../services/db_service.dart';
import '../services/weight_service.dart';
import '../services/print_service.dart';
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

  // 称重相关
  double _currentKg = 0.0;
  bool _weightStable = false;  // 秤示数是否稳定
  bool _weightValid = false;   // 是否有有效重量
  bool _scaleConnected = false;
  StreamSubscription<WeightData>? _weightSub;

  // 当前选中的菜单项（等待称重确认）
  MenuItem? _selectedItem;

  // 打印机状态
  bool _printerConnected = false;

  // 固定价格商品数量输入
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
    // 自动读取 SharedPreferences 中的串口设置（Settings页面保存的）
    final ok = await _weight.open();
    if (!mounted) return;
    setState(() => _scaleConnected = ok);
    if (ok) {
      _weightSub = _weight.weightStream.listen((data) {
        if (!mounted) return;
        setState(() {
          _currentKg = data.kg;
          _weightStable = data.stable;
          _weightValid = data.valid && data.kg > 0;
        });
      });
    }
  }

  Future<void> _connectPrinter() async {
    final ok = await _print.connect();
    if (!mounted) return;
    setState(() => _printerConnected = ok);
  }

  // ── 购物车操作 ─────────────────────────────────────────────

  void _selectMenuItem(MenuItem item) {
    setState(() {
      _selectedItem = item;
      _fixedQty = 1;
    });
  }

  /// 将当前选中商品加入购物车
  void _addToCart() {
    if (_selectedItem == null) return;
    final item = _selectedItem!;

    double qty;
    double subtotal;

    if (item.isByWeight) {
      if (!_weightValid || _currentKg <= 0) {
        _showSnack('请先放上商品称重');
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

  // ── 打印 ──────────────────────────────────────────────────

  Future<void> _printReceipt() async {
    if (_cart.isEmpty) {
      _showSnack('购物车为空');
      return;
    }
    _showSnack('正在打印…');
    final ok = await _print.printTicket(
      shopName: 'ร้านอาหาร',
      items: _cart,
      total: _total,
    );
    if (!mounted) return;
    setState(() => _printerConnected = ok || _printerConnected);
    _showSnack(ok ? '打印成功！' : '打印失败，请检查打印机');
    if (ok) _clearCart();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // 左：菜单选择区
          Expanded(flex: 5, child: _buildMenuPanel()),
          const VerticalDivider(width: 1, thickness: 1),
          // 右：购物车 + 称重 + 操作区
          Expanded(flex: 4, child: _buildCartPanel()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1976D2),
      foregroundColor: Colors.white,
      title: const Text('收银台 / แคชเชียร์', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        // 称重状态指示
        _StatusDot(
          label: '秤',
          connected: _scaleConnected,
          onTap: _connectScale,
        ),
        const SizedBox(width: 8),
        // 打印机状态指示
        _StatusDot(
          label: '打印机',
          connected: _printerConnected,
          onTap: _connectPrinter,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.restaurant_menu),
          tooltip: '菜单管理',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MenuScreen()),
            );
            _loadMenu();
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '设置',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  // ── 左侧菜单面板 ──────────────────────────────────────────

  Widget _buildMenuPanel() {
    if (_menuItems.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.no_food, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('暂无菜单，请先添加商品', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemCount: _menuItems.length,
        itemBuilder: (_, i) => _MenuCard(
          item: _menuItems[i],
          selected: _selectedItem?.id == _menuItems[i].id,
          onTap: () => _selectMenuItem(_menuItems[i]),
        ),
      ),
    );
  }

  // ── 右侧购物车面板 ────────────────────────────────────────

  Widget _buildCartPanel() {
    return Column(
      children: [
        // 称重 + 商品选中操作区
        _buildWeightSection(),
        const Divider(height: 1),
        // 购物车列表
        Expanded(child: _buildCartList()),
        const Divider(height: 1),
        // 合计 + 打印按钮
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildWeightSection() {
    final hasSelected = _selectedItem != null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前选中商品
          if (hasSelected) ...[
            Row(children: [
              const Icon(Icons.touch_app, size: 18, color: Colors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedItem!.nameTh,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _selectedItem!.isByWeight
                    ? '${_selectedItem!.price.toStringAsFixed(2)} ฿/kg'
                    : '${_selectedItem!.price.toStringAsFixed(2)} ฿/件',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 10),
          ],

          // 称重显示
          if (hasSelected && _selectedItem!.isByWeight) ...[
            _WeightDisplay(kg: _currentKg, valid: _weightValid),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.exposure_zero),
                  label: const Text('去皮'),
                  onPressed: () => _weight.tare(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('加入'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _addToCart,
                ),
              ),
            ]),
          ],

          // 固定价格商品：数量选择
          if (hasSelected && !_selectedItem!.isByWeight) ...[
            Row(children: [
              const Text('数量：', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              _QtyButton(
                icon: Icons.remove,
                onPressed: () => setState(() => _fixedQty = (_fixedQty - 1).clamp(1, 99)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_fixedQty',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onPressed: () => setState(() => _fixedQty = (_fixedQty + 1).clamp(1, 99)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('加入'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                ),
                onPressed: _addToCart,
              ),
            ]),
          ],

          // 未选择商品时的提示
          if (!hasSelected)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('← 请从左侧选择商品', style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    if (_cart.isEmpty) {
      return const Center(
        child: Text('购物车为空', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _cart.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = _cart[i];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          title: Text(item.menuItem.nameTh,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(
            '${item.weightLabel}  ×  ${item.menuItem.price.toStringAsFixed(2)} ฿',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              '${item.subtotal.toStringAsFixed(2)} ฿',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _removeCartItem(i),
              color: Colors.red,
              visualDensity: VisualDensity.compact,
            ),
          ]),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 合计
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('รวม / 合计', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              '${_total.toStringAsFixed(2)} ฿',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
          ]),
          const Spacer(),
          // 清除
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_sweep),
            label: const Text('清空'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _cart.isEmpty ? null : _clearCart,
          ),
          const SizedBox(width: 10),
          // 打印
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 22),
            label: const Text('打印出票', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _cart.isEmpty ? null : _printReceipt,
          ),
        ],
      ),
    );
  }
}

// ── 子组件 ────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MenuCard({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x441565C0), blurRadius: 8, offset: Offset(0, 3))]
              : [const BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.isByWeight ? Icons.scale : Icons.fastfood,
                size: 28,
                color: selected ? Colors.white : const Color(0xFF1976D2),
              ),
              const SizedBox(height: 6),
              Text(
                item.nameTh,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.nameCn.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.nameCn,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                item.isByWeight
                    ? '${item.price.toStringAsFixed(2)} ฿/kg'
                    : '${item.price.toStringAsFixed(2)} ฿/件',
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white70 : Colors.deepOrange,
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

  const _WeightDisplay({required this.kg, required this.valid});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: valid ? Colors.green : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.scale, color: valid ? Colors.green : Colors.grey),
          const SizedBox(width: 10),
          Text(
            '${kg.toStringAsFixed(3)} kg',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valid ? const Color(0xFF2E7D32) : Colors.grey,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (valid) ...[
            const Spacer(),
            Text(
              '= ${(kg * 1000).toStringAsFixed(0)} g',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final bool connected;
  final VoidCallback onTap;

  const _StatusDot({required this.label, required this.connected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      ),
    );
  }
}


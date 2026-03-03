import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/menu_item.dart';

class DbService {
  static final DbService _instance = DbService._();
  factory DbService() => _instance;
  DbService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'cashier.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE menu_items (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name_th    TEXT NOT NULL,
            name_cn    TEXT DEFAULT '',
            price      REAL NOT NULL,
            is_by_weight INTEGER NOT NULL DEFAULT 1
          )
        ''');
        // 预置几条示例菜单
        await db.insert('menu_items', {
          'name_th': 'ผักบุ้ง',
          'name_cn': '空心菜',
          'price': 20.0,
          'is_by_weight': 1,
        });
        await db.insert('menu_items', {
          'name_th': 'หมูสับ',
          'name_cn': '猪肉末',
          'price': 80.0,
          'is_by_weight': 1,
        });
        await db.insert('menu_items', {
          'name_th': 'ไก่ทอด',
          'name_cn': '炸鸡',
          'price': 15.0,
          'is_by_weight': 0,
        });
      },
    );
  }

  // ── 菜单 CRUD ─────────────────────────────────────────────

  Future<List<MenuItem>> getMenuItems() async {
    final rows = await (await db).query('menu_items', orderBy: 'id ASC');
    return rows.map(MenuItem.fromMap).toList();
  }

  Future<MenuItem> insertMenuItem(MenuItem item) async {
    final id = await (await db).insert('menu_items', item.toMap()..remove('id'));
    return item.copyWith(id: id);
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await (await db).update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteMenuItem(int id) async {
    await (await db).delete('menu_items', where: 'id = ?', whereArgs: [id]);
  }
}

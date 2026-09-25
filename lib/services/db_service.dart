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
    return openAt(path);
  }

  static Future<Database> openAt(String path) {
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE menu_items (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name_en    TEXT NOT NULL DEFAULT '',
            name_th    TEXT NOT NULL,
            name_cn    TEXT DEFAULT '',
            price      REAL NOT NULL,
            is_by_weight INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await _seedDefaultMenuIfEmpty(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE menu_items ADD COLUMN name_en TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 3) {
          await _seedDefaultMenuIfEmpty(db);
        }
      },
    );
  }

  static Future<void> _seedDefaultMenuIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM menu_items'),
    );
    if (count != 0) return;
    await db.insert('menu_items', const MenuItem(
      nameEn: 'Weighing Item',
      nameTh: 'สินค้าชั่งน้ำหนัก',
      nameCn: '称重商品',
      price: 1,
      isByWeight: true,
    ).toMap()..remove('id'));
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

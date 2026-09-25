import 'dart:io';

import 'package:cashier_trae/services/db_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('new database gets one editable weighing item only once', () async {
    final directory = await Directory.systemTemp.createTemp('cashier-seed-');
    final path = join(directory.path, 'cashier.db');
    try {
      var db = await DbService.openAt(path);
      var rows = await db.query('menu_items');
      expect(rows, hasLength(1));
      expect(rows.single['name_en'], 'Weighing Item');
      expect(rows.single['name_th'], 'สินค้าชั่งน้ำหนัก');
      expect(rows.single['name_cn'], '称重商品');
      expect(rows.single['price'], 1.0);
      expect(rows.single['is_by_weight'], 1);
      await db.delete('menu_items');
      await db.close();

      db = await DbService.openAt(path);
      rows = await db.query('menu_items');
      expect(rows, isEmpty);
      await db.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('upgrade seeds an empty existing menu', () async {
    final directory = await Directory.systemTemp.createTemp('cashier-upgrade-empty-');
    final path = join(directory.path, 'cashier.db');
    try {
      final oldDb = await openDatabase(path, version: 2, onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE menu_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name_en TEXT NOT NULL DEFAULT '',
            name_th TEXT NOT NULL,
            name_cn TEXT DEFAULT '',
            price REAL NOT NULL,
            is_by_weight INTEGER NOT NULL DEFAULT 1
          )
        ''');
      });
      await oldDb.close();

      final db = await DbService.openAt(path);
      expect(await db.query('menu_items'), hasLength(1));
      await db.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('upgrade preserves an existing menu without adding a sample', () async {
    final directory = await Directory.systemTemp.createTemp('cashier-upgrade-menu-');
    final path = join(directory.path, 'cashier.db');
    try {
      final oldDb = await openDatabase(path, version: 1, onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE menu_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name_th TEXT NOT NULL,
            name_cn TEXT DEFAULT '',
            price REAL NOT NULL,
            is_by_weight INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.insert('menu_items', {
          'name_th': 'สินค้าเดิม',
          'name_cn': '',
          'price': 5.0,
          'is_by_weight': 1,
        });
      });
      await oldDb.close();

      final db = await DbService.openAt(path);
      final rows = await db.query('menu_items');
      expect(rows, hasLength(1));
      expect(rows.single['name_th'], 'สินค้าเดิม');
      expect(rows.single['name_en'], '');
      await db.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

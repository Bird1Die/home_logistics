import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/home_store.dart';
import '../models/inventory_item.dart';
import '../models/shopping_list_entry.dart';
import 'inventory_store.dart';

class SqliteInventoryStore implements InventoryStore {
  Database? _database;

  Future<Database> get _db async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = await getDatabasesPath();
    final db = await openDatabase(
      path.join(databasePath, 'home_logistics.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE inventory_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brand TEXT,
            category TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            minimum_quantity INTEGER NOT NULL,
            unit TEXT NOT NULL,
            preferred_store_id INTEGER
          )
        ''');
        await _createCategoriesTable(db);
        await _createStoresTable(db);
        await _createShoppingTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoriesTable(db);
          await _backfillCategoriesFromItems(db);
        }
        if (oldVersion < 3) {
          await _addPreferredStoreColumn(db);
          await _createStoresTable(db);
          await _createShoppingTables(db);
        }
      },
    );

    _database = db;
    return db;
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE
      )
    ''');
  }

  Future<void> _createStoresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        UNIQUE(name, category) ON CONFLICT IGNORE
      )
    ''');
  }

  Future<void> _createShoppingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_list_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_entry_stores (
        entry_id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        PRIMARY KEY(entry_id, store_id)
      )
    ''');
  }

  Future<void> _addPreferredStoreColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(inventory_items)');
    final hasColumn = columns.any(
      (column) => column['name'] == 'preferred_store_id',
    );
    if (!hasColumn) {
      await db.execute(
        'ALTER TABLE inventory_items ADD COLUMN preferred_store_id INTEGER',
      );
    }
  }

  Future<void> _backfillCategoriesFromItems(Database db) async {
    await db.execute('''
      INSERT OR IGNORE INTO categories (name)
      SELECT DISTINCT category FROM inventory_items
    ''');
  }

  @override
  Future<List<InventoryItem>> loadItems() async {
    final db = await _db;
    final rows = await db.query('inventory_items', orderBy: 'id DESC');
    return rows.map(InventoryItem.fromMap).toList(growable: false);
  }

  @override
  Future<List<String>> loadCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return rows.map((row) => row['name'] as String).toList(growable: false);
  }

  @override
  Future<List<HomeStore>> loadStores() async {
    final db = await _db;
    final rows = await db.query('stores', orderBy: 'category, name');
    return rows.map(HomeStore.fromMap).toList(growable: false);
  }

  @override
  Future<List<ShoppingListEntry>> loadShoppingListEntries() async {
    final db = await _db;
    final entryRows = await db.query(
      'shopping_list_entries',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );
    final storeRows = await db.query('shopping_entry_stores');

    return entryRows
        .map((entryRow) {
          final entryId = entryRow['id'] as int;
          final storeIds = storeRows
              .where((storeRow) => storeRow['entry_id'] == entryId)
              .map((storeRow) => storeRow['store_id'] as int)
              .toList(growable: false);

          return ShoppingListEntry.fromMap(entryRow, storeIds: storeIds);
        })
        .toList(growable: false);
  }

  @override
  Future<void> addCategory(String category) async {
    final db = await _db;
    await db.insert('categories', {
      'name': category,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> updateCategory(String oldCategory, String newCategory) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'name': newCategory},
        where: 'name = ? COLLATE NOCASE',
        whereArgs: [oldCategory],
      );
      await txn.update(
        'inventory_items',
        {'category': newCategory},
        where: 'category = ? COLLATE NOCASE',
        whereArgs: [oldCategory],
      );
      await txn.update(
        'stores',
        {'category': newCategory},
        where: 'category = ? COLLATE NOCASE',
        whereArgs: [oldCategory],
      );
      await txn.update(
        'shopping_list_entries',
        {'category': newCategory},
        where: 'category = ? COLLATE NOCASE',
        whereArgs: [oldCategory],
      );
    });
  }

  @override
  Future<void> deleteCategory(String category) async {
    final db = await _db;
    await db.delete(
      'categories',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [category],
    );
  }

  @override
  Future<HomeStore> addStore(HomeStore store) async {
    final db = await _db;
    final id = await db.insert(
      'stores',
      store.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (id == 0) {
      final rows = await db.query(
        'stores',
        where: 'name = ? COLLATE NOCASE AND category = ? COLLATE NOCASE',
        whereArgs: [store.name, store.category],
        limit: 1,
      );
      return HomeStore.fromMap(rows.first);
    }

    return store.copyWith(id: id);
  }

  @override
  Future<void> updateStore(HomeStore store) async {
    final id = store.id;
    if (id == null) {
      return;
    }

    final db = await _db;
    await db.update(
      'stores',
      store.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteStore(HomeStore store) async {
    final id = store.id;
    if (id == null) {
      return;
    }

    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'inventory_items',
        {'preferred_store_id': null},
        where: 'preferred_store_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'shopping_entry_stores',
        where: 'store_id = ?',
        whereArgs: [id],
      );
      await txn.delete('stores', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<ShoppingListEntry> addShoppingListEntry(
    ShoppingListEntry entry,
  ) async {
    final db = await _db;
    final id = await db.insert(
      'shopping_list_entries',
      entry.toMap()..remove('id'),
    );

    for (final storeId in entry.storeIds) {
      await db.insert('shopping_entry_stores', {
        'entry_id': id,
        'store_id': storeId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    return entry.copyWith(id: id);
  }

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    final db = await _db;
    final id = await db.insert(
      'inventory_items',
      item.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return item.copyWith(id: id);
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    final db = await _db;
    await db.update(
      'inventory_items',
      item.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteItem(InventoryItem item) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    final db = await _db;
    await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteShoppingListEntry(ShoppingListEntry entry) async {
    final id = entry.id;
    if (id == null) {
      return;
    }

    final db = await _db;
    await db.update(
      'shopping_list_entries',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

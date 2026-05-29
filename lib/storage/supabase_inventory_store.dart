import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_store.dart';
import '../models/home_task.dart';
import '../models/home_task_completion.dart';
import '../models/inventory_item.dart';
import '../models/shopping_list_entry.dart';
import 'inventory_store.dart';

class SupabaseInventoryStore implements InventoryStore {
  SupabaseInventoryStore(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sessione scaduta. Accedi di nuovo.');
    }

    return userId;
  }

  @override
  Future<List<InventoryItem>> loadItems() async {
    final rows = await _client
        .from('inventory_items')
        .select()
        .order('id', ascending: false);

    return rows.map(_inventoryItemFromRow).toList(growable: false);
  }

  @override
  Future<List<String>> loadCategories() async {
    final rows = await _client.from('categories').select('name').order('name');

    return rows.map((row) => row['name'] as String).toList(growable: false);
  }

  @override
  Future<List<HomeStore>> loadStores() async {
    final rows = await _client
        .from('stores')
        .select()
        .order('category')
        .order('name');

    return rows.map(_homeStoreFromRow).toList(growable: false);
  }

  @override
  Future<List<ShoppingListEntry>> loadShoppingListEntries() async {
    final entryRows = await _client
        .from('shopping_list_entries')
        .select()
        .eq('is_completed', false)
        .order('id', ascending: false);
    final storeRows = await _client.from('shopping_entry_stores').select();

    return entryRows
        .map((entryRow) {
          final entryId = entryRow['id'] as int;
          final storeIds = storeRows
              .where((storeRow) => storeRow['entry_id'] == entryId)
              .map((storeRow) => storeRow['store_id'] as int)
              .toList(growable: false);

          return _shoppingEntryFromRow(entryRow, storeIds: storeIds);
        })
        .toList(growable: false);
  }

  @override
  Future<void> addCategory(String category) async {
    final userId = _userId;

    await _client.from('categories').upsert({
      'user_id': userId,
      'name': category,
    }, onConflict: 'user_id,name');
  }

  @override
  Future<void> updateCategory(String oldCategory, String newCategory) async {
    final userId = _userId;

    await _client
        .from('categories')
        .update({'name': newCategory})
        .eq('user_id', userId)
        .eq('name', oldCategory);
    await _client
        .from('inventory_items')
        .update({'category': newCategory})
        .eq('user_id', userId)
        .eq('category', oldCategory);
    await _client
        .from('stores')
        .update({'category': newCategory})
        .eq('user_id', userId)
        .eq('category', oldCategory);
    await _client
        .from('shopping_list_entries')
        .update({'category': newCategory})
        .eq('user_id', userId)
        .eq('category', oldCategory);
  }

  @override
  Future<void> deleteCategory(String category) async {
    final userId = _userId;

    await _client
        .from('categories')
        .delete()
        .eq('user_id', userId)
        .eq('name', category);
  }

  @override
  Future<HomeStore> addStore(HomeStore store) async {
    final userId = _userId;

    final row = await _client
        .from('stores')
        .upsert({
          'user_id': userId,
          'name': store.name,
          'category': store.category,
        }, onConflict: 'user_id,name,category')
        .select()
        .single();

    return _homeStoreFromRow(row);
  }

  @override
  Future<void> updateStore(HomeStore store) async {
    final userId = _userId;
    final id = store.id;
    if (id == null) {
      return;
    }

    await _client
        .from('stores')
        .update({'name': store.name, 'category': store.category})
        .eq('user_id', userId)
        .eq('id', id);
  }

  @override
  Future<void> deleteStore(HomeStore store) async {
    final userId = _userId;
    final id = store.id;
    if (id == null) {
      return;
    }

    await _client
        .from('inventory_items')
        .update({'preferred_store_id': null})
        .eq('user_id', userId)
        .eq('preferred_store_id', id);
    await _client
        .from('shopping_entry_stores')
        .delete()
        .eq('user_id', userId)
        .eq('store_id', id);
    await _client.from('stores').delete().eq('user_id', userId).eq('id', id);
  }

  @override
  Future<ShoppingListEntry> addShoppingListEntry(
    ShoppingListEntry entry,
  ) async {
    final userId = _userId;

    final row = await _client
        .from('shopping_list_entries')
        .insert({
          'user_id': userId,
          'name': entry.name,
          'category': entry.category,
          'is_completed': entry.isCompleted,
        })
        .select()
        .single();
    final entryId = row['id'] as int;

    for (final storeId in entry.storeIds) {
      await _client.from('shopping_entry_stores').insert({
        'user_id': userId,
        'entry_id': entryId,
        'store_id': storeId,
      });
    }

    return _shoppingEntryFromRow(row, storeIds: entry.storeIds);
  }

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    final userId = _userId;

    final row = await _client
        .from('inventory_items')
        .insert({
          'user_id': userId,
          'name': item.name,
          'brand': item.brand,
          'category': item.category,
          'quantity': item.quantity,
          'minimum_quantity': item.minimumQuantity,
          'unit': item.unit,
          'preferred_store_id': item.preferredStoreId,
        })
        .select()
        .single();

    return _inventoryItemFromRow(row);
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    await _client
        .from('inventory_items')
        .update({
          'name': item.name,
          'brand': item.brand,
          'category': item.category,
          'quantity': item.quantity,
          'minimum_quantity': item.minimumQuantity,
          'unit': item.unit,
          'preferred_store_id': item.preferredStoreId,
        })
        .eq('id', id);
  }

  @override
  Future<void> deleteItem(InventoryItem item) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    await _client.from('inventory_items').delete().eq('id', id);
  }

  @override
  Future<void> deleteShoppingListEntry(ShoppingListEntry entry) async {
    final id = entry.id;
    if (id == null) {
      return;
    }

    await _client
        .from('shopping_list_entries')
        .update({'is_completed': true})
        .eq('id', id);
  }

  @override
  Future<List<HomeTask>> loadTasks() async {
    final rows = await _client
        .from('home_tasks')
        .select()
        .eq('is_active', true)
        .eq('is_completed', false)
        .order('next_due_date');

    return rows.map(_homeTaskFromRow).toList(growable: false);
  }

  @override
  Future<List<HomeTaskCompletion>> loadTaskCompletions() async {
    final rows = await _client
        .from('home_task_completions')
        .select()
        .order('completed_at', ascending: false);

    return rows.map(_taskCompletionFromRow).toList(growable: false);
  }

  @override
  Future<HomeTask> addTask(HomeTask task) async {
    final userId = _userId;

    final row = await _client
        .from('home_tasks')
        .insert({
          'user_id': userId,
          'title': task.title,
          'notes': task.notes,
          'recurrence_days': task.recurrenceDays,
          'next_due_date': _dateToString(task.nextDueDate),
          'is_completed': task.isCompleted,
          'is_active': task.isActive,
        })
        .select()
        .single();

    return _homeTaskFromRow(row);
  }

  @override
  Future<void> updateTask(HomeTask task) async {
    final userId = _userId;
    final id = task.id;
    if (id == null) {
      return;
    }

    await _client
        .from('home_tasks')
        .update({
          'title': task.title,
          'notes': task.notes,
          'recurrence_days': task.recurrenceDays,
          'next_due_date': _dateToString(task.nextDueDate),
          'is_completed': task.isCompleted,
          'is_active': task.isActive,
        })
        .eq('user_id', userId)
        .eq('id', id);
  }

  @override
  Future<void> deleteTask(HomeTask task) async {
    final userId = _userId;
    final id = task.id;
    if (id == null) {
      return;
    }

    await _client
        .from('home_tasks')
        .delete()
        .eq('user_id', userId)
        .eq('id', id);
  }

  @override
  Future<void> completeTask(HomeTask task) async {
    final userId = _userId;
    final id = task.id;
    if (id == null) {
      return;
    }

    final now = DateTime.now();
    await _client.from('home_task_completions').insert({
      'user_id': userId,
      'task_id': id,
      'task_title': task.title,
      'completed_at': now.toIso8601String(),
    });

    final recurrenceDays = task.recurrenceDays;
    if (recurrenceDays == null) {
      await _client
          .from('home_tasks')
          .update({'is_completed': true, 'is_active': false})
          .eq('user_id', userId)
          .eq('id', id);
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    final baseDate = task.nextDueDate.isAfter(today) ? task.nextDueDate : today;
    await _client
        .from('home_tasks')
        .update({
          'next_due_date': _dateToString(
            baseDate.add(Duration(days: recurrenceDays)),
          ),
        })
        .eq('user_id', userId)
        .eq('id', id);
  }

  @override
  Future<void> deleteTaskCompletion(HomeTaskCompletion completion) async {
    final userId = _userId;
    final id = completion.id;
    if (id == null) {
      return;
    }

    await _client
        .from('home_task_completions')
        .delete()
        .eq('user_id', userId)
        .eq('id', id);
  }

  InventoryItem _inventoryItemFromRow(Map<String, dynamic> row) {
    return InventoryItem(
      id: row['id'] as int?,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      category: row['category'] as String,
      quantity: row['quantity'] as int,
      minimumQuantity: row['minimum_quantity'] as int,
      unit: row['unit'] as String,
      preferredStoreId: row['preferred_store_id'] as int?,
    );
  }

  HomeStore _homeStoreFromRow(Map<String, dynamic> row) {
    return HomeStore(
      id: row['id'] as int?,
      name: row['name'] as String,
      category: row['category'] as String,
    );
  }

  ShoppingListEntry _shoppingEntryFromRow(
    Map<String, dynamic> row, {
    List<int> storeIds = const [],
  }) {
    return ShoppingListEntry(
      id: row['id'] as int?,
      name: row['name'] as String,
      category: row['category'] as String,
      storeIds: storeIds,
      isCompleted: row['is_completed'] as bool? ?? false,
    );
  }

  HomeTask _homeTaskFromRow(Map<String, dynamic> row) {
    return HomeTask(
      id: row['id'] as int?,
      title: row['title'] as String,
      notes: row['notes'] as String?,
      recurrenceDays: row['recurrence_days'] as int?,
      nextDueDate: DateTime.parse(row['next_due_date'] as String),
      isCompleted: row['is_completed'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  HomeTaskCompletion _taskCompletionFromRow(Map<String, dynamic> row) {
    return HomeTaskCompletion(
      id: row['id'] as int?,
      taskId: row['task_id'] as int,
      taskTitle: row['task_title'] as String,
      completedAt: DateTime.parse(row['completed_at'] as String),
    );
  }

  String _dateToString(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }
}

import '../models/home_store.dart';
import '../models/home_task.dart';
import '../models/home_task_completion.dart';
import '../models/inventory_item.dart';
import '../models/shopping_list_entry.dart';
import 'inventory_store.dart';

class InMemoryInventoryStore implements InventoryStore {
  final List<InventoryItem> _items;
  final List<String> _categories;
  final List<HomeStore> _stores;
  final List<ShoppingListEntry> _shoppingEntries;
  final List<HomeTask> _tasks;
  final List<HomeTaskCompletion> _taskCompletions;
  int _nextItemId;
  int _nextStoreId;
  int _nextShoppingEntryId;
  int _nextTaskId;
  int _nextTaskCompletionId;

  InMemoryInventoryStore([
    List<InventoryItem>? items,
    List<String>? categories,
    List<HomeStore>? stores,
    List<ShoppingListEntry>? shoppingEntries,
    List<HomeTask>? tasks,
    List<HomeTaskCompletion>? taskCompletions,
  ]) : _items = List.of(items ?? const []),
       _categories = List.of(categories ?? const []),
       _stores = List.of(stores ?? const []),
       _shoppingEntries = List.of(shoppingEntries ?? const []),
       _tasks = List.of(tasks ?? const []),
       _taskCompletions = List.of(taskCompletions ?? const []),
       _nextItemId = _nextIdFromItems(items),
       _nextStoreId = _nextIdFromStores(stores),
       _nextShoppingEntryId = _nextIdFromShoppingEntries(shoppingEntries),
       _nextTaskId = _nextIdFromTasks(tasks),
       _nextTaskCompletionId = _nextIdFromTaskCompletions(taskCompletions);

  static int _nextIdFromItems(List<InventoryItem>? items) {
    return ((items ?? const <InventoryItem>[])
            .map((item) => item.id ?? 0)
            .fold<int>(0, (maxId, id) => id > maxId ? id : maxId)) +
        1;
  }

  static int _nextIdFromStores(List<HomeStore>? stores) {
    return ((stores ?? const <HomeStore>[])
            .map((store) => store.id ?? 0)
            .fold<int>(0, (maxId, id) => id > maxId ? id : maxId)) +
        1;
  }

  static int _nextIdFromShoppingEntries(List<ShoppingListEntry>? entries) {
    return ((entries ?? const <ShoppingListEntry>[])
            .map((entry) => entry.id ?? 0)
            .fold<int>(0, (maxId, id) => id > maxId ? id : maxId)) +
        1;
  }

  static int _nextIdFromTasks(List<HomeTask>? tasks) {
    return ((tasks ?? const <HomeTask>[])
            .map((task) => task.id ?? 0)
            .fold<int>(0, (maxId, id) => id > maxId ? id : maxId)) +
        1;
  }

  static int _nextIdFromTaskCompletions(List<HomeTaskCompletion>? completions) {
    return ((completions ?? const <HomeTaskCompletion>[])
            .map((completion) => completion.id ?? 0)
            .fold<int>(0, (maxId, id) => id > maxId ? id : maxId)) +
        1;
  }

  @override
  Future<List<InventoryItem>> loadItems() async {
    return List.of(_items);
  }

  @override
  Future<List<String>> loadCategories() async {
    return List.of(_categories)..sort();
  }

  @override
  Future<List<HomeStore>> loadStores() async {
    return List.of(_stores)..sort((a, b) {
      final categoryCompare = a.category.compareTo(b.category);
      return categoryCompare == 0 ? a.name.compareTo(b.name) : categoryCompare;
    });
  }

  @override
  Future<List<ShoppingListEntry>> loadShoppingListEntries() async {
    return _shoppingEntries
        .where((entry) => !entry.isCompleted)
        .toList(growable: false);
  }

  @override
  Future<void> addCategory(String category) async {
    final normalizedCategory = category.trim();
    final alreadyExists = _categories.any(
      (existingCategory) =>
          existingCategory.toLowerCase() == normalizedCategory.toLowerCase(),
    );

    if (normalizedCategory.isEmpty || alreadyExists) {
      return;
    }

    _categories.add(normalizedCategory);
  }

  @override
  Future<void> updateCategory(String oldCategory, String newCategory) async {
    final normalizedCategory = newCategory.trim();
    if (normalizedCategory.isEmpty) {
      return;
    }

    final categoryIndex = _categories.indexWhere(
      (category) => category.toLowerCase() == oldCategory.toLowerCase(),
    );
    if (categoryIndex != -1) {
      _categories[categoryIndex] = normalizedCategory;
    }

    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      if (item.category == oldCategory) {
        _items[index] = item.copyWith(category: normalizedCategory);
      }
    }

    for (var index = 0; index < _stores.length; index++) {
      final store = _stores[index];
      if (store.category == oldCategory) {
        _stores[index] = store.copyWith(category: normalizedCategory);
      }
    }

    for (var index = 0; index < _shoppingEntries.length; index++) {
      final entry = _shoppingEntries[index];
      if (entry.category == oldCategory) {
        _shoppingEntries[index] = entry.copyWith(category: normalizedCategory);
      }
    }
  }

  @override
  Future<void> deleteCategory(String category) async {
    _categories.removeWhere(
      (existingCategory) =>
          existingCategory.toLowerCase() == category.toLowerCase(),
    );
  }

  @override
  Future<HomeStore> addStore(HomeStore store) async {
    final existingStore = _stores.where(
      (existingStore) =>
          existingStore.name.toLowerCase() == store.name.toLowerCase() &&
          existingStore.category.toLowerCase() == store.category.toLowerCase(),
    );
    if (existingStore.isNotEmpty) {
      return existingStore.first;
    }

    final savedStore = store.copyWith(id: _nextStoreId);
    _nextStoreId++;
    _stores.add(savedStore);
    return savedStore;
  }

  @override
  Future<void> updateStore(HomeStore store) async {
    final index = _stores.indexWhere(
      (existingStore) => existingStore.id == store.id,
    );
    if (index == -1) {
      return;
    }

    _stores[index] = store;
  }

  @override
  Future<void> deleteStore(HomeStore store) async {
    final storeId = store.id;
    _stores.removeWhere((existingStore) => existingStore.id == storeId);
    if (storeId == null) {
      return;
    }

    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      if (item.preferredStoreId == storeId) {
        _items[index] = item.copyWith(clearPreferredStoreId: true);
      }
    }

    for (var index = 0; index < _shoppingEntries.length; index++) {
      final entry = _shoppingEntries[index];
      if (entry.storeIds.contains(storeId)) {
        _shoppingEntries[index] = entry.copyWith(
          storeIds: entry.storeIds
              .where((entryStoreId) => entryStoreId != storeId)
              .toList(growable: false),
        );
      }
    }
  }

  @override
  Future<ShoppingListEntry> addShoppingListEntry(
    ShoppingListEntry entry,
  ) async {
    final savedEntry = entry.copyWith(id: _nextShoppingEntryId);
    _nextShoppingEntryId++;
    _shoppingEntries.insert(0, savedEntry);
    return savedEntry;
  }

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    final savedItem = item.copyWith(id: _nextItemId);
    _nextItemId++;
    _items.insert(0, savedItem);
    return savedItem;
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    final index = _items.indexWhere(
      (existingItem) => existingItem.id == item.id,
    );
    if (index == -1) {
      return;
    }

    _items[index] = item;
  }

  @override
  Future<void> deleteItem(InventoryItem item) async {
    _items.removeWhere((existingItem) => existingItem.id == item.id);
  }

  @override
  Future<void> deleteShoppingListEntry(ShoppingListEntry entry) async {
    final index = _shoppingEntries.indexWhere(
      (existingEntry) => existingEntry.id == entry.id,
    );
    if (index == -1) {
      return;
    }

    _shoppingEntries[index] = entry.copyWith(isCompleted: true);
  }

  @override
  Future<List<HomeTask>> loadTasks() async {
    return _tasks
        .where((task) => task.isActive && !task.isCompleted)
        .toList(growable: false)
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  @override
  Future<List<HomeTaskCompletion>> loadTaskCompletions() async {
    return List.of(_taskCompletions)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  @override
  Future<HomeTask> addTask(HomeTask task) async {
    final savedTask = task.copyWith(id: _nextTaskId);
    _nextTaskId++;
    _tasks.add(savedTask);
    return savedTask;
  }

  @override
  Future<void> updateTask(HomeTask task) async {
    final index = _tasks.indexWhere(
      (existingTask) => existingTask.id == task.id,
    );
    if (index == -1) {
      return;
    }

    _tasks[index] = task;
  }

  @override
  Future<void> deleteTask(HomeTask task) async {
    _tasks.removeWhere((existingTask) => existingTask.id == task.id);
  }

  @override
  Future<void> completeTask(HomeTask task) async {
    final id = task.id;
    if (id == null) {
      return;
    }

    _taskCompletions.insert(
      0,
      HomeTaskCompletion(
        id: _nextTaskCompletionId,
        taskId: id,
        taskTitle: task.title,
        completedAt: DateTime.now(),
      ),
    );
    _nextTaskCompletionId++;

    final index = _tasks.indexWhere((existingTask) => existingTask.id == id);
    if (index == -1) {
      return;
    }

    final recurrenceDays = task.recurrenceDays;
    if (recurrenceDays == null) {
      _tasks[index] = task.copyWith(isCompleted: true, isActive: false);
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final baseDate = task.nextDueDate.isAfter(todayDate)
        ? task.nextDueDate
        : todayDate;
    _tasks[index] = task.copyWith(
      nextDueDate: baseDate.add(Duration(days: recurrenceDays)),
    );
  }

  @override
  Future<void> deleteTaskCompletion(HomeTaskCompletion completion) async {
    _taskCompletions.removeWhere(
      (existingCompletion) => existingCompletion.id == completion.id,
    );
  }
}

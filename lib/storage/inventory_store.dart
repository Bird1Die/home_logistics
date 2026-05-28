import '../models/inventory_item.dart';
import '../models/home_store.dart';
import '../models/shopping_list_entry.dart';

abstract class InventoryStore {
  Future<List<InventoryItem>> loadItems();
  Future<List<String>> loadCategories();
  Future<List<HomeStore>> loadStores();
  Future<List<ShoppingListEntry>> loadShoppingListEntries();
  Future<void> addCategory(String category);
  Future<void> updateCategory(String oldCategory, String newCategory);
  Future<void> deleteCategory(String category);
  Future<HomeStore> addStore(HomeStore store);
  Future<void> updateStore(HomeStore store);
  Future<void> deleteStore(HomeStore store);
  Future<ShoppingListEntry> addShoppingListEntry(ShoppingListEntry entry);
  Future<InventoryItem> addItem(InventoryItem item);
  Future<void> updateItem(InventoryItem item);
  Future<void> deleteItem(InventoryItem item);
  Future<void> deleteShoppingListEntry(ShoppingListEntry entry);
}

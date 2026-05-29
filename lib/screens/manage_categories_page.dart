import 'package:flutter/material.dart';

import '../models/home_store.dart';
import '../models/inventory_item.dart';
import '../models/shopping_list_entry.dart';
import '../storage/inventory_store.dart';
import '../widgets/unfocus_on_tap.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({
    required this.inventoryStore,
    this.embedded = false,
    super.key,
  });

  final InventoryStore inventoryStore;
  final bool embedded;

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final List<String> _categories = [];
  final List<InventoryItem> _items = [];
  final List<HomeStore> _stores = [];
  final List<ShoppingListEntry> _entries = [];
  bool _isLoading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await widget.inventoryStore.loadCategories();
    final items = await widget.inventoryStore.loadItems();
    final stores = await widget.inventoryStore.loadStores();
    final entries = await widget.inventoryStore.loadShoppingListEntries();

    if (!mounted) {
      return;
    }

    setState(() {
      _categories
        ..clear()
        ..addAll(categories);
      _items
        ..clear()
        ..addAll(items);
      _stores
        ..clear()
        ..addAll(stores);
      _entries
        ..clear()
        ..addAll(entries);
      _isLoading = false;
    });
  }

  Future<void> _addCategory() async {
    final category = await _askCategoryName(title: 'Nuova categoria');
    if (category == null) {
      return;
    }

    if (_categoryExists(category)) {
      _showError('$category esiste gia');
      return;
    }

    await widget.inventoryStore.addCategory(category);
    _changed = true;
    await _loadData();
  }

  Future<void> _editCategory(String category) async {
    final newCategory = await _askCategoryName(
      title: 'Modifica categoria',
      initialValue: category,
    );
    if (newCategory == null || newCategory == category) {
      return;
    }

    if (_categoryExists(newCategory)) {
      _showError('$newCategory esiste gia');
      return;
    }

    await widget.inventoryStore.updateCategory(category, newCategory);
    _changed = true;
    await _loadData();
  }

  Future<void> _deleteCategory(String category) async {
    final usedByItems = _items.any((item) => item.category == category);
    final usedByStores = _stores.any((store) => store.category == category);
    final usedByEntries = _entries.any((entry) => entry.category == category);
    if (usedByItems || usedByStores || usedByEntries) {
      _showError('Svuota la categoria prima di eliminarla');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina categoria'),
        content: Text('Vuoi eliminare $category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      return;
    }

    await widget.inventoryStore.deleteCategory(category);
    _changed = true;
    await _loadData();
  }

  bool _categoryExists(String category) {
    return _categories.any(
      (existingCategory) =>
          existingCategory.toLowerCase() == category.toLowerCase(),
    );
  }

  Future<String?> _askCategoryName({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => UnfocusOnTap(
        child: AlertDialog(
          title: Text(title),
          content: TextField(
            key: const Key('managedCategoryNameField'),
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome categoria',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              key: const Key('saveManagedCategoryButton'),
              onPressed: () => Navigator.of(context).pop(controller.text),
              icon: const Icon(Icons.check),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }
    return normalizedValue;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _close() {
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Categorie'),
              leading: IconButton(
                tooltip: 'Indietro',
                onPressed: _close,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Categoria'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? const Center(child: Text('Nessuna categoria'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(category),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Modifica',
                            onPressed: () => _editCategory(category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Elimina',
                            onPressed: () => _deleteCategory(category),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _close();
        }
      },
      child: content,
    );
  }
}

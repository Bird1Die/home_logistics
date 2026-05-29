import 'package:flutter/material.dart';

import '../models/home_store.dart';
import '../storage/inventory_store.dart';
import '../widgets/unfocus_on_tap.dart';

class ManageStoresPage extends StatefulWidget {
  const ManageStoresPage({
    required this.inventoryStore,
    this.embedded = false,
    super.key,
  });

  final InventoryStore inventoryStore;
  final bool embedded;

  @override
  State<ManageStoresPage> createState() => _ManageStoresPageState();
}

class _ManageStoresPageState extends State<ManageStoresPage> {
  final List<String> _categories = [];
  final List<HomeStore> _stores = [];
  bool _isLoading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await widget.inventoryStore.loadCategories();
    final stores = await widget.inventoryStore.loadStores();

    if (!mounted) {
      return;
    }

    setState(() {
      _categories
        ..clear()
        ..addAll(categories);
      _stores
        ..clear()
        ..addAll(stores);
      _isLoading = false;
    });
  }

  Future<void> _addStore() async {
    if (_categories.isEmpty) {
      _showError('Crea prima una categoria');
      return;
    }

    final store = await _askStore();
    if (store == null) {
      return;
    }

    if (_storeExists(store)) {
      _showError('${store.name} esiste gia in ${store.category}');
      return;
    }

    await widget.inventoryStore.addStore(store);
    _changed = true;
    await _loadData();
  }

  Future<void> _editStore(HomeStore store) async {
    final updatedStore = await _askStore(initialStore: store);
    if (updatedStore == null) {
      return;
    }

    if (_storeExists(updatedStore, ignoredStoreId: store.id)) {
      _showError('${updatedStore.name} esiste gia in ${updatedStore.category}');
      return;
    }

    await widget.inventoryStore.updateStore(updatedStore);
    _changed = true;
    await _loadData();
  }

  Future<void> _deleteStore(HomeStore store) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina negozio'),
        content: Text('Vuoi eliminare ${store.name}?'),
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

    await widget.inventoryStore.deleteStore(store);
    _changed = true;
    await _loadData();
  }

  bool _storeExists(HomeStore store, {int? ignoredStoreId}) {
    return _stores.any(
      (existingStore) =>
          existingStore.id != ignoredStoreId &&
          existingStore.name.toLowerCase() == store.name.toLowerCase() &&
          existingStore.category.toLowerCase() == store.category.toLowerCase(),
    );
  }

  Future<HomeStore?> _askStore({HomeStore? initialStore}) async {
    final nameController = TextEditingController(
      text: initialStore?.name ?? '',
    );
    var category = initialStore?.category ?? _categories.first;

    final store = await showDialog<HomeStore>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => UnfocusOnTap(
          child: AlertDialog(
            title: Text(initialStore == null ? 'Nuovo negozio' : 'Modifica'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome negozio',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setDialogState(() {
                      category = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(
                    HomeStore(
                      id: initialStore?.id,
                      name: name,
                      category: category,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
    return store;
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
              title: const Text('Negozi'),
              leading: IconButton(
                tooltip: 'Indietro',
                onPressed: _close,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStore,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Negozio'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stores.isEmpty
            ? const Center(child: Text('Nessun negozio'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _stores.length,
                itemBuilder: (context, index) {
                  final store = _stores[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(store.name),
                      subtitle: Text(store.category),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Modifica',
                            onPressed: () => _editStore(store),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Elimina',
                            onPressed: () => _deleteStore(store),
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

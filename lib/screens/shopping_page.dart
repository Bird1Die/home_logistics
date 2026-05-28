import 'package:flutter/material.dart';

import '../models/home_store.dart';
import '../models/inventory_item.dart';
import '../models/shopping_list_entry.dart';
import '../storage/inventory_store.dart';
import '../widgets/account_drawer.dart';
import '../widgets/unfocus_on_tap.dart';
import 'add_item_page.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({
    required this.inventoryStore,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.onSignOut,
    super.key,
  });

  final InventoryStore inventoryStore;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onSignOut;

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final List<InventoryItem> _items = [];
  final List<String> _categories = [];
  final List<HomeStore> _stores = [];
  final List<ShoppingListEntry> _manualEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await widget.inventoryStore.loadItems();
    final categories = await widget.inventoryStore.loadCategories();
    final stores = await widget.inventoryStore.loadStores();
    final manualEntries = await widget.inventoryStore.loadShoppingListEntries();

    if (!mounted) {
      return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _categories
        ..clear()
        ..addAll(categories);
      _stores
        ..clear()
        ..addAll(stores);
      _manualEntries
        ..clear()
        ..addAll(manualEntries);
      _isLoading = false;
    });
  }

  List<InventoryItem> get _automaticItems {
    return _items.where((item) => item.needsRestock).toList(growable: false);
  }

  List<_ShoppingStoreGroup> get _groups {
    final groups = <_ShoppingStoreGroup>[];
    final storesByCategory = <String, List<HomeStore>>{};
    for (final store in _stores) {
      storesByCategory.putIfAbsent(store.category, () => []).add(store);
    }

    for (final store in _stores) {
      groups.add(_ShoppingStoreGroup(store: store));
    }

    for (final item in _automaticItems) {
      final preferredStoreId = item.preferredStoreId;
      if (preferredStoreId != null) {
        final group = groups.where(
          (group) => group.store.id == preferredStoreId,
        );
        if (group.isNotEmpty) {
          group.first.automaticItems.add(item);
          continue;
        }
      }

      final categoryStores = storesByCategory[item.category] ?? const [];
      if (categoryStores.isEmpty) {
        groups
            .firstWhere(
              (group) =>
                  group.store.id == null &&
                  group.store.category == item.category,
              orElse: () {
                final group = _ShoppingStoreGroup(
                  store: HomeStore(
                    name: item.category,
                    category: item.category,
                  ),
                );
                groups.add(group);
                return group;
              },
            )
            .automaticItems
            .add(item);
      } else {
        for (final store in categoryStores) {
          groups
              .firstWhere((group) => group.store.id == store.id)
              .automaticItems
              .add(item);
        }
      }
    }

    for (final entry in _manualEntries) {
      if (entry.storeIds.isNotEmpty) {
        for (final storeId in entry.storeIds) {
          final group = groups.where((group) => group.store.id == storeId);
          if (group.isNotEmpty) {
            group.first.manualEntries.add(entry);
          }
        }
        continue;
      }

      final categoryStores = storesByCategory[entry.category] ?? const [];
      if (categoryStores.isEmpty) {
        groups
            .firstWhere(
              (group) =>
                  group.store.id == null &&
                  group.store.category == entry.category,
              orElse: () {
                final group = _ShoppingStoreGroup(
                  store: HomeStore(
                    name: entry.category,
                    category: entry.category,
                  ),
                );
                groups.add(group);
                return group;
              },
            )
            .manualEntries
            .add(entry);
      } else {
        for (final store in categoryStores) {
          groups
              .firstWhere((group) => group.store.id == store.id)
              .manualEntries
              .add(entry);
        }
      }
    }

    return groups
        .where(
          (group) =>
              group.automaticItems.isNotEmpty || group.manualEntries.isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<void> _openAddStoreDialog() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crea prima una categoria')));
      return;
    }

    var storeName = '';
    var category = _categories.first;

    final store = await showDialog<HomeStore>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return UnfocusOnTap(
              child: AlertDialog(
                title: const Text('Nuovo negozio'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('storeNameField'),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nome negozio',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        storeName = value;
                      },
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
                    key: const Key('saveStoreButton'),
                    onPressed: () {
                      final normalizedName = storeName.trim();
                      if (normalizedName.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(
                        HomeStore(name: normalizedName, category: category),
                      );
                    },
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (store == null) {
      return;
    }

    final savedStore = await widget.inventoryStore.addStore(store);
    if (!mounted) {
      return;
    }

    setState(() {
      final alreadyExists = _stores.any((store) => store.id == savedStore.id);
      if (!alreadyExists) {
        _stores.add(savedStore);
      }
    });
  }

  Future<void> _openAddManualEntryDialog() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crea prima una categoria')));
      return;
    }

    var itemName = '';
    var category = _categories.first;
    final selectedStoreIds = <int>{};

    final entry = await showDialog<ShoppingListEntry>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableStores = _stores
                .where((store) => store.category == category)
                .toList(growable: false);

            return UnfocusOnTap(
              child: AlertDialog(
                title: const Text('Aggiungi alla spesa'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        key: const Key('manualEntryNameField'),
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nome item',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          itemName = value;
                        },
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
                            selectedStoreIds.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Negozi',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (availableStores.isEmpty)
                        const Text('Nessun negozio per questa categoria')
                      else
                        ...availableStores.map(
                          (store) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(store.name),
                            value: selectedStoreIds.contains(store.id),
                            onChanged: (selected) {
                              setDialogState(() {
                                if (selected == true && store.id != null) {
                                  selectedStoreIds.add(store.id!);
                                } else {
                                  selectedStoreIds.remove(store.id);
                                }
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
                  ),
                  FilledButton.icon(
                    key: const Key('saveManualEntryButton'),
                    onPressed: () {
                      final normalizedName = itemName.trim();
                      if (normalizedName.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(
                        ShoppingListEntry(
                          name: normalizedName,
                          category: category,
                          storeIds: selectedStoreIds.toList(growable: false),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (entry == null) {
      return;
    }

    final savedEntry = await widget.inventoryStore.addShoppingListEntry(entry);
    if (!mounted) {
      return;
    }

    setState(() {
      _manualEntries.insert(0, savedEntry);
    });
  }

  Future<void> _markAutomaticBought(InventoryItem item) async {
    final quantity = await _askBoughtQuantity(item.unit);
    if (quantity == null) {
      return;
    }

    final updatedItem = item.copyWith(quantity: item.quantity + quantity);
    await widget.inventoryStore.updateItem(updatedItem);
    await _loadData();
  }

  Future<void> _markManualBought(ShoppingListEntry entry) async {
    final newItem = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(
        builder: (context) => AddItemPage(
          categories: _categories,
          stores: _stores,
          initialItem: InventoryItem(
            name: entry.name,
            category: entry.category,
            quantity: 1,
            minimumQuantity: 1,
          ),
        ),
      ),
    );

    if (newItem == null) {
      return;
    }

    await widget.inventoryStore.addItem(newItem);
    await widget.inventoryStore.deleteShoppingListEntry(entry);
    await _loadData();
  }

  Future<void> _openGroupPage(_ShoppingStoreGroup group) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _ShoppingStoreListPage(
          group: group,
          onAutomaticBought: _markAutomaticBought,
          onManualBought: _markManualBought,
        ),
      ),
    );

    await _loadData();
  }

  Future<int?> _askBoughtQuantity(String unit) async {
    var quantityText = '1';

    return showDialog<int>(
      context: context,
      builder: (context) {
        return UnfocusOnTap(
          child: AlertDialog(
            title: const Text('Quantita comprata'),
            content: TextField(
              key: const Key('boughtQuantityField'),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantita ($unit)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                quantityText = value;
              },
              onSubmitted: (value) {
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return;
                }
                Navigator.of(context).pop(quantity);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              FilledButton(
                key: const Key('confirmBoughtQuantityButton'),
                onPressed: () {
                  final quantity = int.tryParse(quantityText);
                  if (quantity == null || quantity <= 0) {
                    return;
                  }
                  Navigator.of(context).pop(quantity);
                },
                child: const Text('Conferma'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;

    return Scaffold(
      endDrawer: AccountDrawer(
        inventoryStore: widget.inventoryStore,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onDataChanged: () {
          _loadData();
        },
        onSignOut: widget.onSignOut,
      ),
      appBar: AppBar(
        title: const Text('Spesa'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: 'Account',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.account_circle_outlined),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: UnfocusOnTap(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('addManualEntryButton'),
                      onPressed: _openAddManualEntryDialog,
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Item manuale'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('addStoreButton'),
                      onPressed: _openAddStoreDialog,
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Negozio'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('Nessun item da comprare')),
                )
              else
                ...groups.map(
                  (group) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      key: Key('shoppingGroup-${group.store.name}'),
                      title: Text(group.store.name),
                      subtitle: Text(
                        group.store.id == null
                            ? 'Categoria senza negozi'
                            : group.store.category,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(label: Text('${group.totalCount}')),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _openGroupPage(group),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingStoreListPage extends StatelessWidget {
  const _ShoppingStoreListPage({
    required this.group,
    required this.onAutomaticBought,
    required this.onManualBought,
  });

  final _ShoppingStoreGroup group;
  final Future<void> Function(InventoryItem item) onAutomaticBought;
  final Future<void> Function(ShoppingListEntry entry) onManualBought;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.store.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              group.store.category,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (group.automaticItems.isEmpty && group.manualEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('Lista vuota')),
              )
            else ...[
              ...group.automaticItems.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      'Hai ${item.quantity} ${item.unit} • Min ${item.minimumQuantity}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await onAutomaticBought(item);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Comprato'),
                    ),
                  ),
                ),
              ),
              ...group.manualEntries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.edit_note_outlined),
                    title: Text(entry.name),
                    subtitle: const Text('Item manuale'),
                    trailing: TextButton(
                      onPressed: () async {
                        await onManualBought(entry);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Comprato'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShoppingStoreGroup {
  _ShoppingStoreGroup({required this.store});

  final HomeStore store;
  final List<InventoryItem> automaticItems = [];
  final List<ShoppingListEntry> manualEntries = [];

  int get totalCount => automaticItems.length + manualEntries.length;
}

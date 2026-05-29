import 'package:flutter/material.dart';

import '../models/home_store.dart';
import '../models/inventory_item.dart';
import '../storage/inventory_store.dart';
import '../widgets/account_drawer.dart';
import '../widgets/empty_inventory_message.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/unfocus_on_tap.dart';
import 'add_item_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
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
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const List<String> _systemFilters = ['Tutto', 'Da comprare'];

  String _selectedCategory = 'Tutto';
  final TextEditingController _searchController = TextEditingController();
  final List<InventoryItem> _items = [];
  final List<String> _categories = [];
  final List<HomeStore> _stores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await widget.inventoryStore.loadItems();
    final categories = await widget.inventoryStore.loadCategories();
    final stores = await widget.inventoryStore.loadStores();

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
      _isLoading = false;
    });
  }

  List<String> get _filterOptions {
    return [..._systemFilters, ..._categories];
  }

  List<InventoryItem> get _visibleItems {
    late final List<InventoryItem> categoryItems;

    if (_selectedCategory == 'Tutto') {
      categoryItems = _items;
    } else if (_selectedCategory == 'Da comprare') {
      categoryItems = _items
          .where((item) => item.needsRestock)
          .toList(growable: false);
    } else {
      categoryItems = _items
          .where((item) => item.category == _selectedCategory)
          .toList(growable: false);
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return categoryItems;
    }

    return categoryItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              (item.brand?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
  }

  int get _warningRestockCount =>
      _items.where((item) => item.needsRestock && item.quantity > 0).length;

  int get _criticalRestockCount =>
      _items.where((item) => item.quantity == 0).length;

  Future<void> _openAddItemPage() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crea prima una categoria')));
      return;
    }

    final newItem = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(
        builder: (context) =>
            AddItemPage(categories: _categories, stores: _stores),
      ),
    );

    if (newItem == null) {
      return;
    }

    final savedItem = await widget.inventoryStore.addItem(newItem);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCategory = 'Tutto';
      _items.insert(0, savedItem);
    });
  }

  Future<void> _openEditItemPage(InventoryItem item) async {
    final updatedItem = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(
        builder: (context) => AddItemPage(
          categories: _categories,
          stores: _stores,
          initialItem: item,
          onDelete: () => _confirmDeleteItem(item),
        ),
      ),
    );

    if (updatedItem == null) {
      return;
    }

    final savedItem = updatedItem.copyWith(id: item.id);
    await widget.inventoryStore.updateItem(savedItem);

    if (!mounted) {
      return;
    }

    setState(() {
      final itemIndex = _items.indexOf(item);
      if (itemIndex != -1) {
        _items[itemIndex] = savedItem;
      }
    });
  }

  Future<void> _confirmDeleteItem(InventoryItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina item'),
          content: Text('Vuoi eliminare ${item.name} dall\'inventario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton.tonalIcon(
              key: const Key('confirmDeleteItemButton'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.inventoryStore.deleteItem(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    setState(() {
      _items.remove(item);
    });
  }

  Future<void> _changeQuantity(InventoryItem item, int change) async {
    final updatedItem = item.copyWith(
      quantity: (item.quantity + change).clamp(0, 999),
    );

    await widget.inventoryStore.updateItem(updatedItem);

    if (!mounted) {
      return;
    }

    setState(() {
      final itemIndex = _items.indexOf(item);
      if (itemIndex != -1) {
        _items[itemIndex] = updatedItem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      endDrawer: AccountDrawer(
        inventoryStore: widget.inventoryStore,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onDataChanged: () {
          _loadItems();
        },
        onSignOut: widget.onSignOut,
      ),
      appBar: AppBar(
        title: const Text('Home Logistics'),
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
        child: Stack(
          children: [
            UnfocusOnTap(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  TextField(
                    key: const Key('inventorySearchField'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca per nome o marca',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Cancella ricerca',
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._filterOptions.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (visibleItems.isEmpty)
                    const EmptyInventoryMessage()
                  else
                    ...visibleItems.map(
                      (item) => InventoryItemCard(
                        item: item,
                        onDecrease: () => _changeQuantity(item, -1),
                        onIncrease: () => _changeQuantity(item, 1),
                        onEdit: () => _openEditItemPage(item),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: _RestockCounterBadge(
                warningCount: _warningRestockCount,
                criticalCount: _criticalRestockCount,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RestockCounterBadge extends StatelessWidget {
  const _RestockCounterBadge({
    required this.warningCount,
    required this.criticalCount,
  });

  final int warningCount;
  final int criticalCount;

  @override
  Widget build(BuildContext context) {
    if (warningCount == 0 && criticalCount == 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (warningCount > 0)
              _RestockCounterSegment(
                key: const Key('warningRestockCounterBadge'),
                count: warningCount,
                iconColor: Colors.amber.shade700,
              ),
            if (warningCount > 0 && criticalCount > 0)
              const SizedBox(width: 12),
            if (criticalCount > 0)
              _RestockCounterSegment(
                key: const Key('criticalRestockCounterBadge'),
                count: criticalCount,
                iconColor: colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }
}

class _RestockCounterSegment extends StatelessWidget {
  const _RestockCounterSegment({
    required this.count,
    required this.iconColor,
    super.key,
  });

  final int count;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

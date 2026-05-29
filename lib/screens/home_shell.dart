import 'package:flutter/material.dart';

import '../storage/inventory_store.dart';
import '../widgets/account_drawer.dart';
import 'inventory_page.dart';
import 'manage_categories_page.dart';
import 'manage_stores_page.dart';
import 'shopping_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
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

  void _openInventoryModule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryModuleShell(
          inventoryStore: inventoryStore,
          themeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: AccountDrawer(
        themeMode: themeMode,
        onThemeModeChanged: onThemeModeChanged,
        onSignOut: onSignOut,
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Casa',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _HomeModuleCard(
              key: const Key('inventoryModuleCard'),
              title: 'Inventario',
              subtitle: 'Prodotti, spesa, categorie e negozi',
              icon: Icons.inventory_2_outlined,
              onTap: () => _openInventoryModule(context),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryModuleShell extends StatefulWidget {
  const InventoryModuleShell({
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
  State<InventoryModuleShell> createState() => _InventoryModuleShellState();
}

class _InventoryModuleShellState extends State<InventoryModuleShell> {
  int _selectedIndex = 0;

  String get _title {
    return switch (_selectedIndex) {
      0 => 'Inventario',
      1 => 'Spesa',
      2 => 'Categorie',
      _ => 'Negozi',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: AccountDrawer(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onSignOut: widget.onSignOut,
      ),
      appBar: AppBar(
        title: Text(_title),
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
      body: switch (_selectedIndex) {
        0 => InventoryPage(inventoryStore: widget.inventoryStore),
        1 => ShoppingPage(inventoryStore: widget.inventoryStore),
        2 => ManageCategoriesPage(
          inventoryStore: widget.inventoryStore,
          embedded: true,
        ),
        _ => ManageStoresPage(
          inventoryStore: widget.inventoryStore,
          embedded: true,
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Spesa',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorie',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Negozi',
          ),
        ],
      ),
    );
  }
}

class _HomeModuleCard extends StatelessWidget {
  const _HomeModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

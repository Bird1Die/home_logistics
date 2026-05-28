import 'package:flutter/material.dart';

import '../storage/inventory_store.dart';
import 'inventory_page.dart';
import 'shopping_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.inventoryStore, this.onSignOut, super.key});

  final InventoryStore inventoryStore;
  final VoidCallback? onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? InventoryPage(
              inventoryStore: widget.inventoryStore,
              onSignOut: widget.onSignOut,
            )
          : ShoppingPage(
              inventoryStore: widget.inventoryStore,
              onSignOut: widget.onSignOut,
            ),
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
        ],
      ),
    );
  }
}

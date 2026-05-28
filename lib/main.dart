import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'storage/in_memory_inventory_store.dart';
import 'storage/inventory_store.dart';
import 'storage/sqlite_inventory_store.dart';

void main() {
  final inventoryStore = kIsWeb
      ? InMemoryInventoryStore()
      : SqliteInventoryStore();

  runApp(HomeLogisticsApp(inventoryStore: inventoryStore));
}

class HomeLogisticsApp extends StatelessWidget {
  const HomeLogisticsApp({required this.inventoryStore, super.key});

  final InventoryStore inventoryStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Logistics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: HomeShell(inventoryStore: inventoryStore),
    );
  }
}

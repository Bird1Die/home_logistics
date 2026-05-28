import 'package:flutter/material.dart';

import '../screens/manage_categories_page.dart';
import '../screens/manage_stores_page.dart';
import '../screens/settings_page.dart';
import '../storage/inventory_store.dart';

class AccountDrawer extends StatelessWidget {
  const AccountDrawer({
    required this.inventoryStore,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onDataChanged,
    this.onSignOut,
    super.key,
  });

  final InventoryStore inventoryStore;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onDataChanged;
  final VoidCallback? onSignOut;

  Future<void> _openManagementPage(BuildContext context, Widget page) async {
    final navigator = Navigator.of(context);
    Navigator.of(context).pop();
    final changed = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => page),
    );
    if (changed == true) {
      onDataChanged();
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    final navigator = Navigator.of(context);
    Navigator.of(context).pop();
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          themeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged,
          canChangePassword: onSignOut != null,
        ),
      ),
    );
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pop();
    onSignOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Account'),
              subtitle: onSignOut == null
                  ? const Text('Modalita locale')
                  : const Text('Home Logistics'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categorie'),
              onTap: () => _openManagementPage(
                context,
                ManageCategoriesPage(inventoryStore: inventoryStore),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Negozi'),
              onTap: () => _openManagementPage(
                context,
                ManageStoresPage(inventoryStore: inventoryStore),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Impostazioni'),
              onTap: () => _openSettings(context),
            ),
            const Spacer(),
            if (onSignOut != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => _signOut(context),
              ),
          ],
        ),
      ),
    );
  }
}

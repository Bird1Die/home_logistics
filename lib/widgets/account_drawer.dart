import 'package:flutter/material.dart';

import '../screens/settings_page.dart';

class AccountDrawer extends StatelessWidget {
  const AccountDrawer({
    required this.themeMode,
    required this.onThemeModeChanged,
    this.onSignOut,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onSignOut;

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

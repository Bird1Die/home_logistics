import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_page.dart';
import 'screens/home_shell.dart';
import 'storage/in_memory_inventory_store.dart';
import 'storage/inventory_store.dart';
import 'storage/sqlite_inventory_store.dart';
import 'storage/supabase_inventory_store.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hasSupabaseConfig =
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  if (hasSupabaseConfig) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  final inventoryStore = _createLocalStore(hasSupabaseConfig);

  runApp(
    HomeLogisticsApp(
      inventoryStore: inventoryStore,
      useSupabase: hasSupabaseConfig,
    ),
  );
}

InventoryStore _createLocalStore(bool hasSupabaseConfig) {
  if (hasSupabaseConfig) {
    return SupabaseInventoryStore(Supabase.instance.client);
  }

  return kIsWeb ? InMemoryInventoryStore() : SqliteInventoryStore();
}

class HomeLogisticsApp extends StatelessWidget {
  const HomeLogisticsApp({
    required this.inventoryStore,
    this.useSupabase = false,
    super.key,
  });

  final InventoryStore inventoryStore;
  final bool useSupabase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Logistics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: useSupabase
          ? SupabaseAuthGate(inventoryStore: inventoryStore)
          : HomeShell(inventoryStore: inventoryStore),
    );
  }
}

class SupabaseAuthGate extends StatefulWidget {
  const SupabaseAuthGate({required this.inventoryStore, super.key});

  final InventoryStore inventoryStore;

  @override
  State<SupabaseAuthGate> createState() => _SupabaseAuthGateState();
}

class _SupabaseAuthGateState extends State<SupabaseAuthGate> {
  late final SupabaseClient _client;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _client.auth.onAuthStateChange.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _signOut() async {
    await _client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = _client.auth.currentSession;
    if (session == null) {
      return const AuthPage();
    }

    return HomeShell(
      key: ValueKey(session.user.id),
      inventoryStore: widget.inventoryStore,
      onSignOut: _signOut,
    );
  }
}

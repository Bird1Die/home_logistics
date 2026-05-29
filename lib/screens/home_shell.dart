import 'package:flutter/material.dart';

import '../models/home_task.dart';
import '../models/inventory_item.dart';
import '../storage/inventory_store.dart';
import '../widgets/account_drawer.dart';
import 'inventory_page.dart';
import 'manage_categories_page.dart';
import 'manage_stores_page.dart';
import 'shopping_page.dart';
import 'task_history_page.dart';
import 'tasks_page.dart';

class HomeShell extends StatefulWidget {
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

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final List<InventoryItem> _items = [];
  final List<HomeTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeCounters();
  }

  Future<void> _loadHomeCounters() async {
    final items = await widget.inventoryStore.loadItems();
    final tasks = await widget.inventoryStore.loadTasks();

    if (!mounted) {
      return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _tasks
        ..clear()
        ..addAll(tasks);
      _isLoading = false;
    });
  }

  int get _inventoryWarningCount =>
      _items.where((item) => item.needsRestock && item.quantity > 0).length;

  int get _inventoryCriticalCount =>
      _items.where((item) => item.quantity == 0).length;

  int get _todayTaskCount {
    final today = _today();
    return _tasks.where((task) => _isSameDay(task.nextDueDate, today)).length;
  }

  int get _overdueTaskCount {
    final today = _today();
    return _tasks.where((task) => task.nextDueDate.isBefore(today)).length;
  }

  void _openInventoryModule(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => InventoryModuleShell(
              inventoryStore: widget.inventoryStore,
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
              onSignOut: widget.onSignOut,
            ),
          ),
        )
        .then((_) => _loadHomeCounters());
  }

  void _openTasksModule(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TasksModuleShell(
              inventoryStore: widget.inventoryStore,
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
              onSignOut: widget.onSignOut,
            ),
          ),
        )
        .then((_) => _loadHomeCounters());
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
              trailingBadge: _isLoading
                  ? null
                  : _InventorySummaryBadge(
                      warningCount: _inventoryWarningCount,
                      criticalCount: _inventoryCriticalCount,
                    ),
            ),
            _HomeModuleCard(
              key: const Key('tasksModuleCard'),
              title: 'Attivita',
              subtitle: 'Routine, manutenzioni e cose da fare',
              icon: Icons.task_alt_outlined,
              onTap: () => _openTasksModule(context),
              trailingBadge: _isLoading
                  ? null
                  : _TaskSummaryBadge(
                      todayCount: _todayTaskCount,
                      overdueCount: _overdueTaskCount,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksModuleShell extends StatefulWidget {
  const TasksModuleShell({
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
  State<TasksModuleShell> createState() => _TasksModuleShellState();
}

class _TasksModuleShellState extends State<TasksModuleShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: AccountDrawer(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onSignOut: widget.onSignOut,
      ),
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Attivita' : 'Attivita fatte'),
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
      body: _selectedIndex == 0
          ? TasksPage(inventoryStore: widget.inventoryStore)
          : TaskHistoryPage(inventoryStore: widget.inventoryStore),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Da fare',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Fatte',
          ),
        ],
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
    this.trailingBadge,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailingBadge;

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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.chevron_right),
                  if (trailingBadge != null) ...[
                    const SizedBox(height: 12),
                    trailingBadge!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventorySummaryBadge extends StatelessWidget {
  const _InventorySummaryBadge({
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warningCount > 0)
            _SummaryCounterSegment(
              key: const Key('homeInventoryWarningCounterBadge'),
              count: warningCount,
              iconColor: Colors.amber.shade700,
            ),
          if (warningCount > 0 && criticalCount > 0) const SizedBox(width: 10),
          if (criticalCount > 0)
            _SummaryCounterSegment(
              key: const Key('homeInventoryCriticalCounterBadge'),
              count: criticalCount,
              iconColor: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }
}

class _TaskSummaryBadge extends StatelessWidget {
  const _TaskSummaryBadge({
    required this.todayCount,
    required this.overdueCount,
  });

  final int todayCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    if (todayCount == 0 && overdueCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (todayCount > 0)
            _SummaryCounterSegment(
              key: const Key('homeTodayTaskCounterBadge'),
              count: todayCount,
              iconColor: Colors.amber.shade700,
            ),
          if (todayCount > 0 && overdueCount > 0) const SizedBox(width: 10),
          if (overdueCount > 0)
            _SummaryCounterSegment(
              key: const Key('homeOverdueTaskCounterBadge'),
              count: overdueCount,
              iconColor: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }
}

class _SummaryCounterSegment extends StatelessWidget {
  const _SummaryCounterSegment({
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
        Icon(Icons.warning_amber_rounded, size: 18, color: iconColor),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool _isSameDay(DateTime firstDate, DateTime secondDate) {
  return firstDate.year == secondDate.year &&
      firstDate.month == secondDate.month &&
      firstDate.day == secondDate.day;
}

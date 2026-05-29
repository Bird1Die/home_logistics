import 'package:flutter/material.dart';

import '../models/home_task.dart';
import '../storage/inventory_store.dart';
import 'add_task_page.dart';
import 'task_details_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({required this.inventoryStore, super.key});

  final InventoryStore inventoryStore;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<HomeTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await widget.inventoryStore.loadTasks();
    if (!mounted) {
      return;
    }

    setState(() {
      _tasks
        ..clear()
        ..addAll(tasks);
      _isLoading = false;
    });
  }

  Future<void> _openAddTaskPage() async {
    final task = await Navigator.of(
      context,
    ).push<HomeTask>(MaterialPageRoute(builder: (_) => const AddTaskPage()));
    if (task == null) {
      return;
    }

    await widget.inventoryStore.addTask(task);
    await _loadTasks();
  }

  Future<void> _completeTask(HomeTask task) async {
    await widget.inventoryStore.completeTask(task);
    await _loadTasks();
  }

  Future<void> _openTaskDetailsPage(HomeTask task) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailsPage(inventoryStore: widget.inventoryStore, task: task),
      ),
    );
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final today = _today();
    final overdueTasks = _tasks
        .where((task) => task.nextDueDate.isBefore(today))
        .toList(growable: false);
    final todayTasks = _tasks
        .where((task) => _isSameDay(task.nextDueDate, today))
        .toList(growable: false);
    final upcomingTasks =
        _tasks
            .where((task) => task.nextDueDate.isAfter(today))
            .toList(growable: false)
          ..sort((firstTask, secondTask) {
            return firstTask.nextDueDate.compareTo(secondTask.nextDueDate);
          });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? const Center(child: Text('Nessuna attivita'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      if (overdueTasks.isNotEmpty)
                        _TaskSection(
                          title: 'In ritardo',
                          tasks: overdueTasks,
                          status: _TaskStatus.overdue,
                          onComplete: _completeTask,
                          onOpenDetails: _openTaskDetailsPage,
                        ),
                      if (todayTasks.isNotEmpty)
                        _TaskSection(
                          title: 'Oggi',
                          tasks: todayTasks,
                          status: _TaskStatus.today,
                          onComplete: _completeTask,
                          onOpenDetails: _openTaskDetailsPage,
                        ),
                      if (upcomingTasks.isNotEmpty)
                        _TaskSection(
                          title: 'Prossime',
                          tasks: upcomingTasks,
                          status: _TaskStatus.upcoming,
                          onComplete: _completeTask,
                          onOpenDetails: _openTaskDetailsPage,
                        ),
                    ],
                  ),
            Positioned(
              left: 16,
              bottom: 16,
              child: _TaskCounterBadge(
                todayCount: todayTasks.length,
                overdueCount: overdueTasks.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addTaskButton'),
        onPressed: _openAddTaskPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.tasks,
    required this.status,
    required this.onComplete,
    required this.onOpenDetails,
  });

  final String title;
  final List<HomeTask> tasks;
  final _TaskStatus status;
  final ValueChanged<HomeTask> onComplete;
  final ValueChanged<HomeTask> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ...tasks.map(
          (task) => _TaskCard(
            task: task,
            status: status,
            onComplete: () => onComplete(task),
            onOpenDetails: () => onOpenDetails(task),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.status,
    required this.onComplete,
    required this.onOpenDetails,
  });

  final HomeTask task;
  final _TaskStatus status;
  final VoidCallback onComplete;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (status) {
      _TaskStatus.overdue => Theme.of(context).colorScheme.error,
      _TaskStatus.today => Colors.amber.shade700,
      _TaskStatus.upcoming => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final iconData = switch (status) {
      _TaskStatus.overdue => Icons.warning_amber_rounded,
      _TaskStatus.today => Icons.warning_amber_rounded,
      _TaskStatus.upcoming => Icons.schedule_outlined,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onOpenDetails,
        leading: Icon(iconData, color: iconColor),
        title: Text(task.title),
        subtitle: Text(
          [
            task.isOneTime
                ? 'Una tantum'
                : 'Ogni ${task.recurrenceDays} giorni',
            'Prossima: ${_formatDate(task.nextDueDate)}',
            if (task.notes != null && task.notes!.isNotEmpty) task.notes!,
          ].join(' • '),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Completa',
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCounterBadge extends StatelessWidget {
  const _TaskCounterBadge({
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
            if (todayCount > 0)
              _TaskCounterSegment(
                key: const Key('todayTaskCounterBadge'),
                count: todayCount,
                iconColor: Colors.amber.shade700,
              ),
            if (todayCount > 0 && overdueCount > 0) const SizedBox(width: 12),
            if (overdueCount > 0)
              _TaskCounterSegment(
                key: const Key('overdueTaskCounterBadge'),
                count: overdueCount,
                iconColor: colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskCounterSegment extends StatelessWidget {
  const _TaskCounterSegment({
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

enum _TaskStatus { overdue, today, upcoming }

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool _isSameDay(DateTime firstDate, DateTime secondDate) {
  return firstDate.year == secondDate.year &&
      firstDate.month == secondDate.month &&
      firstDate.day == secondDate.day;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

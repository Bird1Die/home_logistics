import 'package:flutter/material.dart';

import '../models/home_task.dart';
import '../storage/inventory_store.dart';
import 'add_task_page.dart';

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

  Future<void> _openEditTaskPage(HomeTask task) async {
    final updatedTask = await Navigator.of(context).push<HomeTask>(
      MaterialPageRoute(
        builder: (_) => AddTaskPage(
          initialTask: task,
          onDelete: () => _confirmDeleteTask(task),
        ),
      ),
    );
    if (updatedTask == null) {
      return;
    }

    await widget.inventoryStore.updateTask(updatedTask);
    await _loadTasks();
  }

  Future<void> _confirmDeleteTask(HomeTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina attivita'),
        content: Text('Vuoi eliminare ${task.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton.tonalIcon(
            key: const Key('confirmDeleteTaskButton'),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      return;
    }

    await widget.inventoryStore.deleteTask(task);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    await _loadTasks();
  }

  Future<void> _completeTask(HomeTask task) async {
    await widget.inventoryStore.completeTask(task);
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
    final upcomingTasks = _tasks
        .where((task) => task.nextDueDate.isAfter(today))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
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
                      onEdit: _openEditTaskPage,
                    ),
                  if (todayTasks.isNotEmpty)
                    _TaskSection(
                      title: 'Oggi',
                      tasks: todayTasks,
                      status: _TaskStatus.today,
                      onComplete: _completeTask,
                      onEdit: _openEditTaskPage,
                    ),
                  if (upcomingTasks.isNotEmpty)
                    _TaskSection(
                      title: 'Prossime',
                      tasks: upcomingTasks,
                      status: _TaskStatus.upcoming,
                      onComplete: _completeTask,
                      onEdit: _openEditTaskPage,
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
    required this.onEdit,
  });

  final String title;
  final List<HomeTask> tasks;
  final _TaskStatus status;
  final ValueChanged<HomeTask> onComplete;
  final ValueChanged<HomeTask> onEdit;

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
            onEdit: () => onEdit(task),
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
    required this.onEdit,
  });

  final HomeTask task;
  final _TaskStatus status;
  final VoidCallback onComplete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _TaskStatus.overdue => Theme.of(context).colorScheme.error,
      _TaskStatus.today => Colors.amber.shade700,
      _TaskStatus.upcoming => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: color),
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
            IconButton(
              tooltip: 'Modifica',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
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

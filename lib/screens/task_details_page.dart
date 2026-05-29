import 'package:flutter/material.dart';

import '../models/home_task.dart';
import '../storage/inventory_store.dart';
import 'add_task_page.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({
    required this.inventoryStore,
    required this.task,
    super.key,
  });

  final InventoryStore inventoryStore;
  final HomeTask task;

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late HomeTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _openEditTaskPage() async {
    final updatedTask = await Navigator.of(context).push<HomeTask>(
      MaterialPageRoute(
        builder: (_) => AddTaskPage(
          initialTask: _task,
          onDelete: () => _confirmDeleteTask(_task),
        ),
      ),
    );
    if (updatedTask == null) {
      return;
    }

    await widget.inventoryStore.updateTask(updatedTask);

    if (!mounted) {
      return;
    }

    setState(() {
      _task = updatedTask;
    });
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

    Navigator.of(context)
      ..pop()
      ..pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dettagli attivita')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _DetailSection(label: 'Nome', value: _task.title),
            _DetailSection(
              label: 'Cadenza',
              value: _task.isOneTime
                  ? 'Una tantum'
                  : 'Ogni ${_task.recurrenceDays} giorni',
            ),
            _DetailSection(
              label: 'Prossima data',
              value: _formatDate(_task.nextDueDate),
            ),
            if (_task.notes != null && _task.notes!.trim().isNotEmpty)
              _DetailSection(label: 'Note', value: _task.notes!),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('editTaskDetailsButton'),
        tooltip: 'Modifica',
        onPressed: _openEditTaskPage,
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

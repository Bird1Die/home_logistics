import 'package:flutter/material.dart';

import '../models/home_task_completion.dart';
import '../storage/inventory_store.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({required this.inventoryStore, super.key});

  final InventoryStore inventoryStore;

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  final List<HomeTaskCompletion> _completions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }

  Future<void> _loadCompletions() async {
    final completions = await widget.inventoryStore.loadTaskCompletions();
    if (!mounted) {
      return;
    }

    setState(() {
      _completions
        ..clear()
        ..addAll(completions);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _completions.isEmpty
            ? const Center(child: Text('Nessuna attivita completata'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _completions.length,
                itemBuilder: (context, index) {
                  final completion = _completions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(completion.taskTitle),
                      subtitle: Text(_formatDateTime(completion.completedAt)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

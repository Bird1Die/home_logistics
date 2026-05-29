import 'package:flutter/material.dart';

import '../models/home_task.dart';
import '../widgets/unfocus_on_tap.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({this.initialTask, this.onDelete, super.key});

  final HomeTask? initialTask;
  final VoidCallback? onDelete;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _customDaysController;
  late DateTime _nextDueDate;
  late int? _recurrenceDays;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    _titleController = TextEditingController(text: initialTask?.title ?? '');
    _notesController = TextEditingController(text: initialTask?.notes ?? '');
    _recurrenceDays = initialTask?.recurrenceDays;
    _customDaysController = TextEditingController(
      text: _isPresetRecurrence(_recurrenceDays)
          ? ''
          : _recurrenceDays?.toString() ?? '',
    );
    final now = DateTime.now();
    _nextDueDate =
        initialTask?.nextDueDate ?? DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customDays = int.tryParse(_customDaysController.text);
    final recurrenceDays = _recurrenceDays == -1 ? customDays : _recurrenceDays;
    Navigator.of(context).pop(
      HomeTask(
        id: widget.initialTask?.id,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        recurrenceDays: recurrenceDays,
        nextDueDate: _nextDueDate,
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) {
      return;
    }

    setState(() {
      _nextDueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  bool _isPresetRecurrence(int? days) {
    return days == null || days == 1 || days == 7 || days == 30;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }
    return null;
  }

  String? _customDaysValidator(String? value) {
    if (_recurrenceDays != -1) {
      return null;
    }

    final days = int.tryParse(value ?? '');
    if (days == null || days <= 0) {
      return 'Inserisci i giorni';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica attivita' : 'Nuova attivita'),
      ),
      body: SafeArea(
        child: UnfocusOnTap(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                TextFormField(
                  key: const Key('taskTitleField'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nome attivita',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: _requiredText,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  key: const Key('taskRecurrenceField'),
                  initialValue: _isPresetRecurrence(_recurrenceDays)
                      ? _recurrenceDays
                      : -1,
                  decoration: const InputDecoration(
                    labelText: 'Ricorrenza',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Una tantum')),
                    DropdownMenuItem(value: 1, child: Text('Ogni giorno')),
                    DropdownMenuItem(value: 7, child: Text('Ogni settimana')),
                    DropdownMenuItem(value: 30, child: Text('Ogni mese')),
                    DropdownMenuItem(value: -1, child: Text('Ogni X giorni')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurrenceDays = value;
                    });
                  },
                ),
                if (_recurrenceDays == -1) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('taskCustomDaysField'),
                    controller: _customDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Ogni quanti giorni',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _customDaysValidator,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('taskDueDateButton'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('Prossima data: ${_formatDate(_nextDueDate)}'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('taskNotesField'),
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          if (_isEditing && widget.onDelete != null)
            Positioned(
              left: 32,
              bottom: 0,
              child: FloatingActionButton(
                key: const Key('deleteTaskButton'),
                heroTag: 'deleteTaskFab',
                tooltip: 'Elimina',
                onPressed: widget.onDelete,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                child: const Icon(Icons.delete_outline),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              key: const Key('saveTaskButton'),
              heroTag: 'saveTaskFab',
              tooltip: 'Salva',
              onPressed: _saveTask,
              child: const Icon(Icons.save_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

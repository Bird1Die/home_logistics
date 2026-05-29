class HomeTask {
  const HomeTask({
    this.id,
    required this.title,
    required this.nextDueDate,
    this.notes,
    this.recurrenceDays,
    this.isCompleted = false,
    this.isActive = true,
  });

  final int? id;
  final String title;
  final String? notes;
  final int? recurrenceDays;
  final DateTime nextDueDate;
  final bool isCompleted;
  final bool isActive;

  bool get isOneTime => recurrenceDays == null;

  HomeTask copyWith({
    int? id,
    String? title,
    String? notes,
    int? recurrenceDays,
    DateTime? nextDueDate,
    bool? isCompleted,
    bool? isActive,
    bool clearNotes = false,
    bool clearRecurrence = false,
  }) {
    return HomeTask(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: clearNotes ? null : notes ?? this.notes,
      recurrenceDays: clearRecurrence
          ? null
          : recurrenceDays ?? this.recurrenceDays,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'recurrence_days': recurrenceDays,
      'next_due_date': _dateToString(nextDueDate),
      'is_completed': isCompleted ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory HomeTask.fromMap(Map<String, Object?> map) {
    return HomeTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      recurrenceDays: map['recurrence_days'] as int?,
      nextDueDate: _dateFromValue(map['next_due_date']),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  static String _dateToString(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.toIso8601String().split('T').first;
  }

  static DateTime _dateFromValue(Object? value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    return DateTime.parse(value as String);
  }
}

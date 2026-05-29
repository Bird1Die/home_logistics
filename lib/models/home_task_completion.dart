class HomeTaskCompletion {
  const HomeTaskCompletion({
    this.id,
    required this.taskId,
    required this.taskTitle,
    required this.completedAt,
  });

  final int? id;
  final int taskId;
  final String taskTitle;
  final DateTime completedAt;

  HomeTaskCompletion copyWith({
    int? id,
    int? taskId,
    String? taskTitle,
    DateTime? completedAt,
  }) {
    return HomeTaskCompletion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory HomeTaskCompletion.fromMap(Map<String, Object?> map) {
    return HomeTaskCompletion(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      taskTitle: map['task_title'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}

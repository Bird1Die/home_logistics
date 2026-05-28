class ShoppingListEntry {
  const ShoppingListEntry({
    this.id,
    required this.name,
    required this.category,
    this.storeIds = const [],
    this.isCompleted = false,
  });

  final int? id;
  final String name;
  final String category;
  final List<int> storeIds;
  final bool isCompleted;

  ShoppingListEntry copyWith({
    int? id,
    String? name,
    String? category,
    List<int>? storeIds,
    bool? isCompleted,
  }) {
    return ShoppingListEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      storeIds: storeIds ?? this.storeIds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory ShoppingListEntry.fromMap(
    Map<String, Object?> map, {
    List<int> storeIds = const [],
  }) {
    return ShoppingListEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      storeIds: storeIds,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }
}

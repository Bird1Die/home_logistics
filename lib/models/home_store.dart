class HomeStore {
  const HomeStore({this.id, required this.name, required this.category});

  final int? id;
  final String name;
  final String category;

  HomeStore copyWith({int? id, String? name, String? category}) {
    return HomeStore(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'category': category};
  }

  factory HomeStore.fromMap(Map<String, Object?> map) {
    return HomeStore(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
    );
  }
}

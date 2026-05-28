class InventoryItem {
  InventoryItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minimumQuantity,
    this.brand,
    this.unit = 'pz',
    this.preferredStoreId,
  });

  final int? id;
  final String name;
  final String category;
  final String? brand;
  final String unit;
  int quantity;
  final int minimumQuantity;
  final int? preferredStoreId;

  bool get needsRestock => quantity <= minimumQuantity;

  InventoryItem copyWith({
    int? id,
    String? name,
    String? category,
    String? brand,
    String? unit,
    int? quantity,
    int? minimumQuantity,
    int? preferredStoreId,
    bool clearPreferredStoreId = false,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      preferredStoreId: clearPreferredStoreId
          ? null
          : preferredStoreId ?? this.preferredStoreId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'minimum_quantity': minimumQuantity,
      'unit': unit,
      'preferred_store_id': preferredStoreId,
    };
  }

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    return InventoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      category: map['category'] as String,
      quantity: map['quantity'] as int,
      minimumQuantity: map['minimum_quantity'] as int,
      unit: map['unit'] as String,
      preferredStoreId: map['preferred_store_id'] as int?,
    );
  }
}

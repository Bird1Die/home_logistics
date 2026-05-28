import 'package:flutter/material.dart';

import '../models/home_store.dart';
import '../models/inventory_item.dart';
import '../widgets/unfocus_on_tap.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({
    required this.categories,
    this.stores = const [],
    this.initialItem,
    this.onDelete,
    super.key,
  });

  final List<String> categories;
  final List<HomeStore> stores;
  final InventoryItem? initialItem;
  final VoidCallback? onDelete;

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumQuantityController;
  late final TextEditingController _unitController;

  late String _category;
  int? _preferredStoreId;
  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();

    final initialItem = widget.initialItem;
    _nameController = TextEditingController(text: initialItem?.name ?? '');
    _brandController = TextEditingController(text: initialItem?.brand ?? '');
    _quantityController = TextEditingController(
      text: initialItem?.quantity.toString() ?? '1',
    );
    _minimumQuantityController = TextEditingController(
      text: initialItem?.minimumQuantity.toString() ?? '1',
    );
    _unitController = TextEditingController(text: initialItem?.unit ?? 'pz');
    _category = initialItem?.category ?? widget.categories.first;
    _preferredStoreId = initialItem?.preferredStoreId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _minimumQuantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final savedItem = InventoryItem(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      category: _category,
      quantity: int.parse(_quantityController.text),
      minimumQuantity: int.parse(_minimumQuantityController.text),
      unit: _unitController.text.trim(),
      preferredStoreId: _preferredStoreId,
    );

    Navigator.of(context).pop(savedItem);
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }

    return null;
  }

  String? _requiredNumber(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) {
      return 'Inserisci un numero valido';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = {...widget.categories, _category}.toList(
      growable: false,
    )..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final availableStores = widget.stores
        .where((store) => store.category == _category)
        .toList(growable: false);
    final canUsePreferredStore = availableStores.any(
      (store) => store.id == _preferredStoreId,
    );
    if (!canUsePreferredStore) {
      _preferredStoreId = null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifica item' : 'Nuovo item')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_isEditing && widget.onDelete != null)
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Elimina'),
                ),
              ),
            if (_isEditing && widget.onDelete != null) const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const Key('saveItemButton'),
                onPressed: _saveItem,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Salva modifiche' : 'Salva item'),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: UnfocusOnTap(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                TextFormField(
                  key: const Key('itemNameField'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: _requiredText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('itemBrandField'),
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: availableCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _category = value;
                      _preferredStoreId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _preferredStoreId,
                  decoration: const InputDecoration(
                    labelText: 'Negozio preferito',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nessun negozio specifico'),
                    ),
                    ...availableStores.map(
                      (store) => DropdownMenuItem<int?>(
                        value: store.id,
                        child: Text(store.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _preferredStoreId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('itemQuantityField'),
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantita',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('itemMinimumQuantityField'),
                        controller: _minimumQuantityController,
                        decoration: const InputDecoration(
                          labelText: 'Soglia minima',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('itemUnitField'),
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unita',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  validator: _requiredText,
                  onFieldSubmitted: (_) => _saveItem(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

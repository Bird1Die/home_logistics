import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_logistics/main.dart';
import 'package:home_logistics/models/home_store.dart';
import 'package:home_logistics/models/inventory_item.dart';
import 'package:home_logistics/storage/in_memory_inventory_store.dart';

void main() {
  testWidgets('starts with an empty inventory', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(inventoryStore: InMemoryInventoryStore()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventario casa'), findsOneWidget);
    expect(find.text('Nessun item in questa categoria'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Da comprare'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Categoria'), findsOneWidget);
  });

  testWidgets('adds a custom category', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(inventoryStore: InMemoryInventoryStore()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addCategoryChip')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      'Farmaci',
    );
    await tester.tap(find.byKey(const Key('saveCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'Farmaci'), findsOneWidget);
    expect(find.text('Farmaci aggiunta'), findsOneWidget);
  });

  testWidgets('filters items that need restock', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore([
          InventoryItem(
            id: 1,
            name: 'Pasta',
            brand: 'Rummo',
            category: 'Cibo',
            quantity: 3,
            minimumQuantity: 2,
            unit: 'conf.',
          ),
          InventoryItem(
            id: 2,
            name: 'Detersivo piatti',
            category: 'Detersivi',
            quantity: 1,
            minimumQuantity: 1,
            unit: 'flac.',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Da comprare'));
    await tester.pump();

    expect(find.text('Detersivo piatti'), findsOneWidget);
    expect(find.text('Pasta'), findsNothing);
  });

  testWidgets('shows items to buy from the shopping section', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore(
          [
            InventoryItem(
              id: 1,
              name: 'Pasta',
              brand: 'Rummo',
              category: 'Cibo',
              quantity: 3,
              minimumQuantity: 2,
              unit: 'conf.',
            ),
            InventoryItem(
              id: 2,
              name: 'Detersivo piatti',
              category: 'Detersivi',
              quantity: 1,
              minimumQuantity: 1,
              unit: 'flac.',
            ),
          ],
          ['Detersivi'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shoppingCartButton')), findsNothing);

    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();

    expect(find.text('Detersivi'), findsOneWidget);
    expect(find.text('Categoria senza negozi'), findsOneWidget);
    expect(find.text('Detersivo piatti'), findsNothing);

    await tester.tap(find.byKey(const Key('shoppingGroup-Detersivi')));
    await tester.pumpAndSettle();

    expect(find.text('Detersivo piatti'), findsOneWidget);
    expect(find.text('Hai 1 flac. • Min 1'), findsOneWidget);
  });

  testWidgets('shows automatic shopping items by store', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore(
          [
            InventoryItem(
              id: 1,
              name: 'Latte',
              category: 'Cibo',
              quantity: 1,
              minimumQuantity: 1,
              unit: 'conf.',
              preferredStoreId: 1,
            ),
          ],
          ['Cibo'],
          const [HomeStore(id: 1, name: 'MD', category: 'Cibo')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();

    expect(find.text('MD'), findsOneWidget);
    expect(find.text('Latte'), findsNothing);

    await tester.tap(find.byKey(const Key('shoppingGroup-MD')));
    await tester.pumpAndSettle();

    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Hai 1 conf. • Min 1'), findsOneWidget);
  });

  testWidgets('adds manual shopping item to a selected store', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore(
          null,
          ['Cibo'],
          const [
            HomeStore(id: 1, name: 'MD', category: 'Cibo'),
            HomeStore(id: 2, name: 'Castoro', category: 'Cibo'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addManualEntryButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('manualEntryNameField')),
      'Tovaglioli',
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, 'MD'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveManualEntryButton')));
    await tester.pumpAndSettle();

    expect(find.text('MD'), findsOneWidget);
    expect(find.text('Tovaglioli'), findsNothing);
    expect(find.text('Castoro'), findsNothing);

    await tester.tap(find.byKey(const Key('shoppingGroup-MD')));
    await tester.pumpAndSettle();

    expect(find.text('Tovaglioli'), findsOneWidget);
  });

  testWidgets('marks automatic shopping item as bought', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore(
          [
            InventoryItem(
              id: 1,
              name: 'Latte',
              category: 'Cibo',
              quantity: 1,
              minimumQuantity: 1,
              unit: 'conf.',
              preferredStoreId: 1,
            ),
          ],
          ['Cibo'],
          const [HomeStore(id: 1, name: 'MD', category: 'Cibo')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shoppingGroup-MD')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprato'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('boughtQuantityField')), '2');
    await tester.tap(find.byKey(const Key('confirmBoughtQuantityButton')));
    await tester.pumpAndSettle();

    expect(find.text('Nessun item da comprare'), findsOneWidget);

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.text('3 conf.'), findsOneWidget);
  });

  testWidgets('searches items by name and brand only', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore([
          InventoryItem(
            id: 1,
            name: 'Pasta',
            brand: 'Rummo',
            category: 'Cibo',
            quantity: 3,
            minimumQuantity: 2,
            unit: 'conf.',
          ),
          InventoryItem(
            id: 2,
            name: 'Shampoo',
            brand: 'Nivea',
            category: 'Bagno',
            quantity: 2,
            minimumQuantity: 1,
            unit: 'flac.',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventorySearchField')),
      'rum',
    );
    await tester.pump();

    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('Shampoo'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('inventorySearchField')),
      'sham',
    );
    await tester.pump();

    expect(find.text('Shampoo'), findsOneWidget);
    expect(find.text('Pasta'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('inventorySearchField')),
      'bagno',
    );
    await tester.pump();

    expect(find.text('Shampoo'), findsNothing);
    expect(find.text('Pasta'), findsNothing);
  });

  testWidgets('combines search with category filters', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore([
          InventoryItem(
            id: 1,
            name: 'Pasta',
            brand: 'Rummo',
            category: 'Cibo',
            quantity: 3,
            minimumQuantity: 2,
            unit: 'conf.',
          ),
          InventoryItem(
            id: 2,
            name: 'Detersivo piatti',
            brand: 'Svelto',
            category: 'Detersivi',
            quantity: 1,
            minimumQuantity: 1,
            unit: 'flac.',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Da comprare'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('inventorySearchField')),
      'svelto',
    );
    await tester.pump();

    expect(find.text('Detersivo piatti'), findsOneWidget);
    expect(find.text('Pasta'), findsNothing);
  });

  testWidgets('adds a new inventory item', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(inventoryStore: InMemoryInventoryStore(null, ['Cibo'])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('itemNameField')), 'Riso');
    await tester.enterText(find.byKey(const Key('itemBrandField')), 'Scotti');
    await tester.enterText(find.byKey(const Key('itemQuantityField')), '4');
    await tester.enterText(
      find.byKey(const Key('itemMinimumQuantityField')),
      '1',
    );
    await tester.enterText(find.byKey(const Key('itemUnitField')), 'conf.');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Riso'), findsOneWidget);
    expect(find.text('Scotti'), findsOneWidget);
    expect(find.text('4 conf.'), findsOneWidget);
    expect(find.text('Riso aggiunto all\'inventario'), findsOneWidget);
  });

  testWidgets('updates item quantity from the list', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore([
          InventoryItem(
            id: 1,
            name: 'Pasta',
            brand: 'Rummo',
            category: 'Cibo',
            quantity: 3,
            minimumQuantity: 2,
            unit: 'conf.',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 conf.'), findsOneWidget);

    final firstDecreaseButton = find.byIcon(Icons.remove).first;
    await tester.tap(firstDecreaseButton);
    await tester.pump();

    expect(find.text('2 conf.'), findsOneWidget);
  });

  testWidgets('edits an existing inventory item', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore([
          InventoryItem(
            id: 1,
            name: 'Pasta',
            brand: 'Rummo',
            category: 'Cibo',
            quantity: 3,
            minimumQuantity: 2,
            unit: 'conf.',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Modifica item'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('itemBrandField')), 'Barilla');
    await tester.enterText(
      find.byKey(const Key('itemMinimumQuantityField')),
      '5',
    );
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Barilla'), findsOneWidget);
    expect(find.text('Soglia: 5 conf.'), findsOneWidget);
    expect(find.text('Pasta aggiornato'), findsOneWidget);
  });

  testWidgets('deletes an existing inventory item', (tester) async {
    await tester.pumpWidget(
      HomeLogisticsApp(
        inventoryStore: InMemoryInventoryStore([
          InventoryItem(
            id: 1,
            name: 'Pasta',
            brand: 'Rummo',
            category: 'Cibo',
            quantity: 3,
            minimumQuantity: 2,
            unit: 'conf.',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pasta'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Elimina item'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDeleteItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Pasta'), findsNothing);
    expect(find.text('Pasta eliminato'), findsOneWidget);
    expect(find.text('Nessun item in questa categoria'), findsOneWidget);
  });
}

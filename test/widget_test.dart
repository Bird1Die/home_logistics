import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_logistics/main.dart';
import 'package:home_logistics/models/home_store.dart';
import 'package:home_logistics/models/inventory_item.dart';
import 'package:home_logistics/models/home_task.dart';
import 'package:home_logistics/storage/in_memory_inventory_store.dart';

Future<void> pumpHomeLogistics(
  WidgetTester tester,
  InMemoryInventoryStore inventoryStore,
) async {
  await tester.pumpWidget(HomeLogisticsApp(inventoryStore: inventoryStore));
  await tester.pumpAndSettle();
}

Future<void> openInventoryModule(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('inventoryModuleCard')));
  await tester.pumpAndSettle();
}

Future<void> pumpInventoryModule(
  WidgetTester tester,
  InMemoryInventoryStore inventoryStore,
) async {
  await pumpHomeLogistics(tester, inventoryStore);
  await openInventoryModule(tester);
}

void main() {
  testWidgets('starts from the home dashboard', (tester) async {
    await pumpHomeLogistics(tester, InMemoryInventoryStore());

    expect(find.text('Casa'), findsOneWidget);
    expect(find.byKey(const Key('inventoryModuleCard')), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.byTooltip('Account'), findsOneWidget);
  });

  testWidgets('shows inventory and task counters on the home cards', (
    tester,
  ) async {
    await pumpHomeLogistics(
      tester,
      InMemoryInventoryStore(
        [
          InventoryItem(
            id: 1,
            name: 'Pasta',
            category: 'Cibo',
            quantity: 1,
            minimumQuantity: 2,
          ),
          InventoryItem(
            id: 2,
            name: 'Latte',
            category: 'Cibo',
            quantity: 0,
            minimumQuantity: 1,
          ),
        ],
        null,
        null,
        null,
        [
          HomeTask(
            id: 1,
            title: 'Pulire bagno',
            nextDueDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
          HomeTask(id: 2, title: 'Lavastoviglie', nextDueDate: DateTime.now()),
        ],
      ),
    );

    expect(
      find.byKey(const Key('homeInventoryWarningCounterBadge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('homeInventoryCriticalCounterBadge')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('homeTodayTaskCounterBadge')), findsOneWidget);
    expect(
      find.byKey(const Key('homeOverdueTaskCounterBadge')),
      findsOneWidget,
    );
  });

  testWidgets('shows warning and critical restock counters', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
        InventoryItem(
          id: 1,
          name: 'Pasta',
          category: 'Cibo',
          quantity: 1,
          minimumQuantity: 2,
        ),
        InventoryItem(
          id: 2,
          name: 'Latte',
          category: 'Cibo',
          quantity: 0,
          minimumQuantity: 1,
        ),
      ]),
    );

    expect(find.byKey(const Key('warningRestockCounterBadge')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('warningRestockCounterBadge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('criticalRestockCounterBadge')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('criticalRestockCounterBadge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('adds a custom category from the account area', (tester) async {
    await pumpInventoryModule(tester, InMemoryInventoryStore());

    await tester.tap(find.text('Categorie'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Categoria'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('managedCategoryNameField')),
      'Farmaci',
    );
    await tester.tap(find.byKey(const Key('saveManagedCategoryButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'Farmaci'), findsOneWidget);
  });

  testWidgets('adds and completes a one-time task', (tester) async {
    await pumpHomeLogistics(tester, InMemoryInventoryStore());

    await tester.tap(find.byKey(const Key('tasksModuleCard')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna attivita'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addTaskButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('taskTitleField')),
      'Pulire bagno',
    );
    await tester.enterText(
      find.byKey(const Key('taskNotesField')),
      'Usare anticalcare',
    );
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveTaskButton')));
    await tester.pumpAndSettle();

    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Pulire bagno'), findsOneWidget);
    expect(find.byKey(const Key('todayTaskCounterBadge')), findsOneWidget);
    expect(find.byKey(const Key('overdueTaskCounterBadge')), findsNothing);

    await tester.tap(find.byTooltip('Completa'));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna attivita'), findsOneWidget);
    expect(find.byKey(const Key('todayTaskCounterBadge')), findsNothing);
    expect(find.byKey(const Key('overdueTaskCounterBadge')), findsNothing);

    await tester.tap(find.text('Fatte'));
    await tester.pumpAndSettle();

    expect(find.text('Pulire bagno'), findsOneWidget);
  });

  testWidgets(
    'completing a recurring task advances from the current due date',
    (tester) async {
      await pumpHomeLogistics(
        tester,
        InMemoryInventoryStore(null, null, null, null, [
          HomeTask(
            id: 1,
            title: 'Cambiare coperte',
            recurrenceDays: 14,
            nextDueDate: DateTime(2026, 5, 29),
          ),
        ]),
      );

      await tester.tap(find.byKey(const Key('tasksModuleCard')));
      await tester.pumpAndSettle();

      expect(find.textContaining('29/05/2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Completa'));
      await tester.pumpAndSettle();
      expect(find.textContaining('12/06/2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Completa'));
      await tester.pumpAndSettle();
      expect(find.textContaining('26/06/2026'), findsOneWidget);
    },
  );

  testWidgets('shows separate overdue and today task counters', (tester) async {
    await pumpHomeLogistics(
      tester,
      InMemoryInventoryStore(null, null, null, null, [
        HomeTask(
          id: 1,
          title: 'Pulire bagno',
          nextDueDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        HomeTask(id: 2, title: 'Lavastoviglie', nextDueDate: DateTime.now()),
      ]),
    );

    await tester.tap(find.byKey(const Key('tasksModuleCard')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayTaskCounterBadge')), findsOneWidget);
    expect(find.byKey(const Key('overdueTaskCounterBadge')), findsOneWidget);
  });

  testWidgets('deletes a task completion log', (tester) async {
    await pumpHomeLogistics(
      tester,
      InMemoryInventoryStore(null, null, null, null, null, const []),
    );

    await tester.tap(find.byKey(const Key('tasksModuleCard')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addTaskButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('taskTitleField')),
      'Lavatrice',
    );
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveTaskButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Completa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatte'));
    await tester.pumpAndSettle();

    expect(find.text('Lavatrice'), findsOneWidget);

    await tester.tap(find.byTooltip('Elimina log'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirmDeleteTaskCompletionButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nessuna attivita completata'), findsOneWidget);
  });

  testWidgets('filters items that need restock', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
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
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Da comprare'));
    await tester.pump();

    expect(find.text('Detersivo piatti'), findsOneWidget);
    expect(find.text('Pasta'), findsNothing);
  });

  testWidgets('shows items to buy from the shopping section', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore(
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
    );

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
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore(
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
    );

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
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore(
        null,
        ['Cibo'],
        const [
          HomeStore(id: 1, name: 'MD', category: 'Cibo'),
          HomeStore(id: 2, name: 'Castoro', category: 'Cibo'),
        ],
      ),
    );

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
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore(
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
    );

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

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('searches items by name and brand only', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
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
    );

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
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
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
    );

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
    await pumpInventoryModule(tester, InMemoryInventoryStore(null, ['Cibo']));

    await tester.tap(find.byType(FloatingActionButton));
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
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('updates item quantity from the list', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
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
    );

    expect(find.text('3'), findsOneWidget);

    final firstDecreaseButton = find.byIcon(Icons.remove).first;
    await tester.tap(firstDecreaseButton);
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('edits an existing inventory item', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
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
    );

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
  });

  testWidgets('deletes an existing inventory item', (tester) async {
    await pumpInventoryModule(
      tester,
      InMemoryInventoryStore([
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
    );

    expect(find.text('Pasta'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Elimina item'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDeleteItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Pasta'), findsNothing);
    expect(find.text('Nessun item in questa categoria'), findsOneWidget);
  });
}

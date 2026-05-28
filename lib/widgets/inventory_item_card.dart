import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEdit,
    super.key,
  });

  final InventoryItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Restock icon
            if (item.needsRestock)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.warning_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
              ),
            // Product info (left side, expandable)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.brand != null && item.brand!.isNotEmpty)
                    Text(
                      item.brand!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Controls (right side, compact)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: item.quantity == 0 ? null : onDecrease,
                    icon: const Icon(Icons.remove),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton.outlined(
                    tooltip: 'Modifica',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

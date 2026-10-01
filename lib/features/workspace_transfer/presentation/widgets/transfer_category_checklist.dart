import 'package:flutter/material.dart';

import '../../domain/entities/transfer_category.dart';
import '../../domain/entities/transfer_counts.dart';

/// Mindesthöhe für Aktionen in diesem Tab (Touch-Ziel ≥ 48 px).
const transferButtonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, kMinInteractiveDimension)),
);

class TransferCategoryChecklist extends StatelessWidget {
  const TransferCategoryChecklist({
    super.key,
    required this.categories,
    required this.selection,
    required this.onChanged,
    this.counts,
  });

  final List<TransferCategory> categories;
  final Set<TransferCategory> selection;

  /// `null` deaktiviert die Auswahl (z.B. während eines laufenden Vorgangs).
  final void Function(TransferCategory category, bool selected)? onChanged;
  final TransferCounts? counts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final category in categories)
          CheckboxListTile(
            value: selection.contains(category),
            onChanged: onChanged == null
                ? null
                : (selected) => onChanged!(category, selected ?? false),
            title: Text(category.label),
            subtitle: _subtitleFor(category),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget? _subtitleFor(TransferCategory category) {
    final available = counts;
    if (available == null) return null;
    return Text('${available.countOf(category)} ${category.countLabel}');
  }
}

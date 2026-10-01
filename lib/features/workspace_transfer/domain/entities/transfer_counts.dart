import 'transfer_category.dart';

/// Anzahl der Einträge je Bereich — im Manifest eines Exports und als
/// Ergebnis eines Imports.
class TransferCounts {
  TransferCounts(Map<TransferCategory, int> counts)
    : _counts = Map.unmodifiable(counts);

  final Map<TransferCategory, int> _counts;

  List<TransferCategory> get categories => TransferCategory.values
      .where(_counts.containsKey)
      .toList(growable: false);

  int countOf(TransferCategory category) => _counts[category] ?? 0;

  bool get isEmpty => _counts.isEmpty;
}

import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record_query.dart';

String dataCollectionPath(String name) =>
    '/v1/data/collections/${Uri.encodeComponent(name)}';

/// Suche, Filter und Sortierung im Format der Daten-Routen (Abfrage und Export).
Map<String, Object?> dataQueryJson(DataRecordQuery query) => {
  'search': query.search,
  'filters': query.filters
      .where((filter) => filter.field.trim().isNotEmpty)
      .map(_filterJson)
      .toList(growable: false),
  if (query.sort case final sort?)
    'sort': {'field': sort.field, 'direction': sort.direction.wireName},
};

Map<String, Object?> _filterJson(DataFilter filter) => {
  'field': filter.field,
  'operator': filter.operator.wireName,
  'value': filter.value,
};

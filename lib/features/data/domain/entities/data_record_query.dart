import 'package:equatable/equatable.dart';

import 'data_filter.dart';
import 'data_sort.dart';

/// Suche, Filter und Sortierung einer Sammlung — für die Ansicht wie für den Export.
class DataRecordQuery extends Equatable {
  const DataRecordQuery({this.search = '', this.filters = const [], this.sort});

  final String search;
  final List<DataFilter> filters;
  final DataSort? sort;

  @override
  List<Object?> get props => [search, filters, sort];
}

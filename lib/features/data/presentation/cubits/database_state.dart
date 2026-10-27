import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/entities/data_record_query.dart';
import '../../domain/entities/data_sort.dart';

enum DatabaseStatus { loading, collections, records, failure }

class DatabaseState {
  const DatabaseState({
    this.status = DatabaseStatus.loading,
    this.collections = const [],
    this.collection,
    this.records = const [],
    this.search = '',
    this.filters = const [],
    this.sort,
    this.selectedIds = const {},
    this.message,
    this.isMutating = false,
  });

  final DatabaseStatus status;
  final List<DataCollection> collections;
  final DataCollection? collection;
  final List<DataRecord> records;
  final String search;
  final List<DataFilter> filters;
  final DataSort? sort;

  /// IDs der ausgewählten Datensätze; nur sichtbare Datensätze können ausgewählt sein.
  final Set<String> selectedIds;
  final String? message;
  final bool isMutating;

  DataRecordQuery get query =>
      DataRecordQuery(search: search, filters: filters, sort: sort);

  List<DataRecord> get selectedRecords => records
      .where((record) => selectedIds.contains(record.id))
      .toList(growable: false);

  bool get allSelected =>
      records.isNotEmpty && selectedIds.length == records.length;

  DatabaseState copyWith({
    DatabaseStatus? status,
    List<DataCollection>? collections,
    DataCollection? collection,
    bool clearCollection = false,
    List<DataRecord>? records,
    String? search,
    List<DataFilter>? filters,
    DataSort? sort,
    bool clearSort = false,
    Set<String>? selectedIds,
    String? message,
    bool clearMessage = false,
    bool? isMutating,
  }) => DatabaseState(
    status: status ?? this.status,
    collections: collections ?? this.collections,
    collection: clearCollection ? null : collection ?? this.collection,
    records: records ?? this.records,
    search: search ?? this.search,
    filters: filters ?? this.filters,
    sort: clearSort ? null : sort ?? this.sort,
    selectedIds: selectedIds ?? this.selectedIds,
    message: clearMessage ? null : message ?? this.message,
    isMutating: isMutating ?? this.isMutating,
  );
}

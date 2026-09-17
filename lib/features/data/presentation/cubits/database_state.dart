import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record.dart';

enum DatabaseStatus { loading, collections, records, failure }

class DatabaseState {
  const DatabaseState({
    this.status = DatabaseStatus.loading,
    this.collections = const [],
    this.collection,
    this.records = const [],
    this.search = '',
    this.filters = const [],
    this.message,
    this.isMutating = false,
  });

  final DatabaseStatus status;
  final List<DataCollection> collections;
  final DataCollection? collection;
  final List<DataRecord> records;
  final String search;
  final List<DataFilter> filters;
  final String? message;
  final bool isMutating;

  DatabaseState copyWith({
    DatabaseStatus? status,
    List<DataCollection>? collections,
    DataCollection? collection,
    bool clearCollection = false,
    List<DataRecord>? records,
    String? search,
    List<DataFilter>? filters,
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
    message: clearMessage ? null : message ?? this.message,
    isMutating: isMutating ?? this.isMutating,
  );
}

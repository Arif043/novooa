import 'package:equatable/equatable.dart';

enum DataFilterOperator {
  equals,
  notEquals,
  contains,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
}

extension DataFilterOperatorLabel on DataFilterOperator {
  String get label => switch (this) {
    .equals => 'ist gleich',
    .notEquals => 'ist nicht gleich',
    .contains => 'enthält',
    .greaterThan => 'ist größer als',
    .greaterThanOrEqual => 'ist mindestens',
    .lessThan => 'ist kleiner als',
    .lessThanOrEqual => 'ist höchstens',
  };

  String get wireName => switch (this) {
    .equals => 'equals',
    .notEquals => 'notEquals',
    .contains => 'contains',
    .greaterThan => 'greaterThan',
    .greaterThanOrEqual => 'greaterThanOrEqual',
    .lessThan => 'lessThan',
    .lessThanOrEqual => 'lessThanOrEqual',
  };
}

class DataFilter extends Equatable {
  const DataFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final DataFilterOperator operator;
  final Object value;

  DataFilter copyWith({
    String? field,
    DataFilterOperator? operator,
    Object? value,
  }) => DataFilter(
    field: field ?? this.field,
    operator: operator ?? this.operator,
    value: value ?? this.value,
  );

  @override
  List<Object> get props => [field, operator, value];
}

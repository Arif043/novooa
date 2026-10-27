import 'package:equatable/equatable.dart';

enum DataCollectionNameIssue { empty, tooLong }

/// Name einer Datensammlung: getrimmt, nicht leer, höchstens 120 Zeichen — wie in der Runtime.
class DataCollectionName extends Equatable {
  const DataCollectionName._(this.value);

  static const maximumLength = 120;

  final String value;

  static DataCollectionNameIssue? issueOf(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return DataCollectionNameIssue.empty;
    if (trimmed.length > maximumLength) return DataCollectionNameIssue.tooLong;
    return null;
  }

  /// `null`, wenn [input] kein gültiger Name ist; die Gründe nennt [issueOf].
  static DataCollectionName? tryParse(String input) =>
      issueOf(input) == null ? DataCollectionName._(input.trim()) : null;

  @override
  List<Object> get props => [value];
}

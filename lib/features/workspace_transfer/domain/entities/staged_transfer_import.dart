import 'transfer_counts.dart';

class TransferImportId {
  TransferImportId(this.value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Import-ID darf nicht leer sein.',
      );
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is TransferImportId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Ein hochgeladener, geprüfter Export, der noch nicht übernommen wurde.
class StagedTransferImport {
  const StagedTransferImport({
    required this.id,
    required this.exportedAt,
    required this.contents,
  });

  final TransferImportId id;
  final DateTime exportedAt;
  final TransferCounts contents;
}

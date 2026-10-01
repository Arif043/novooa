import '../../domain/entities/staged_transfer_import.dart';
import '../../domain/entities/transfer_category.dart';
import '../../domain/entities/transfer_counts.dart';

/// Übersetzt die JSON-Antworten von `/v1/transfer/*` in Domain-Objekte.
abstract final class TransferResponseModel {
  static StagedTransferImport stagedImportFrom(Map<String, Object?> json) {
    final importId = json['importId'];
    final manifest = json['manifest'];
    if (importId is! String || manifest is! Map) {
      throw const FormatException('Unvollständige Import-Antwort.');
    }
    return StagedTransferImport(
      id: TransferImportId(importId),
      exportedAt: _exportedAt(manifest['exportedAt']),
      contents: countsFrom(manifest['counts']),
    );
  }

  static TransferCounts importedFrom(Map<String, Object?> json) =>
      countsFrom(json['imported']);

  static TransferCounts countsFrom(Object? value) {
    if (value is! Map) throw const FormatException('Mengenangaben fehlen.');
    return TransferCounts({
      for (final entry in value.entries)
        ?TransferCategory.fromApiName(entry.key.toString()):
            (entry.value as num).toInt(),
    });
  }

  static DateTime _exportedAt(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw const FormatException('Exportdatum fehlt.');
    return parsed.toLocal();
  }
}

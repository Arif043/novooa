import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

class NodeOutput {
  const NodeOutput({
    required this.name,
    required this.label,
    required this.value,
    this.type,
  });

  factory NodeOutput.fromStored(String name, Object? storedValue) {
    if (storedValue is Map &&
        storedValue['type'] is String &&
        storedValue.containsKey('value')) {
      return NodeOutput(
        name: name,
        label: NodeOutputFormatter.labelFor(name),
        type: storedValue['type'] as String,
        value: storedValue['value'],
      );
    }
    return NodeOutput(
      name: name,
      label: NodeOutputFormatter.labelFor(name),
      value: storedValue,
    );
  }

  final String name;
  final String label;
  final String? type;
  final Object? value;

  Object? get displayValue {
    if ((type == 'file' || type == 'media') && value is Map) {
      final reference = value as Map;
      return reference['displayName'] ?? value;
    }
    if (type != 'json' || value is! String) return value;
    try {
      return jsonDecode(value as String);
    } on FormatException {
      return value;
    }
  }
}

class NodeOutputFormatter {
  /// Bekannte Ausgabeschlüssel der Bausteine; unbekannte (etwa Felder eines
  /// Formulars oder Datensatzes) bleiben, wie die Nutzer:innen sie benannt haben.
  static const _labelKeys = <String, String>{
    'value': LocaleKeys.output_labels_value,
    'text': LocaleKeys.output_labels_value,
    'sender': LocaleKeys.output_labels_sender,
    'subject': LocaleKeys.output_labels_subject,
    'message': LocaleKeys.output_labels_message,
    'receivedAt': LocaleKeys.output_labels_received_at,
    'recipient': LocaleKeys.output_labels_recipient,
    'channelId': LocaleKeys.output_labels_channel_id,
    'providerMessageId': LocaleKeys.output_labels_provider_message_id,
    'fileId': LocaleKeys.output_labels_file_id,
    'versionId': LocaleKeys.output_labels_version_id,
    'displayName': LocaleKeys.output_labels_display_name,
    'contentType': LocaleKeys.output_labels_content_type,
    'sizeBytes': LocaleKeys.output_labels_size_bytes,
    'folderId': LocaleKeys.output_labels_folder_id,
    'isNewFile': LocaleKeys.output_labels_is_new_file,
    'found': LocaleKeys.output_labels_found,
    'record': LocaleKeys.output_labels_record,
    'documentId': LocaleKeys.output_labels_document_id,
    'total': LocaleKeys.output_labels_total,
    'count': LocaleKeys.output_labels_count,
    'rowCount': LocaleKeys.output_labels_row_count,
    'created': LocaleKeys.output_labels_created,
    'changed': LocaleKeys.output_labels_changed,
    'ok': LocaleKeys.output_labels_ok,
    'status': LocaleKeys.output_labels_status,
    'method': LocaleKeys.output_labels_method,
    'query': LocaleKeys.output_labels_query,
    'headers': LocaleKeys.output_labels_headers,
    'name': LocaleKeys.output_labels_name,
    'mimeType': LocaleKeys.output_labels_mime_type,
    'driveFileId': LocaleKeys.output_labels_drive_file_id,
    'id': LocaleKeys.output_labels_id,
    'event': LocaleKeys.output_labels_event,
    'previousStatus': LocaleKeys.output_labels_previous_status,
    'newStatus': LocaleKeys.output_labels_new_status,
    'paymentStatus': LocaleKeys.output_labels_payment_status,
    'deliveryStatus': LocaleKeys.output_labels_delivery_status,
    'orderNumber': LocaleKeys.output_labels_order_number,
    'customerEmail': LocaleKeys.output_labels_customer_email,
  };

  static String labelFor(String name) {
    final key = _labelKeys[name];
    return key == null ? _humanize(name) : key.tr();
  }

  static String format(NodeOutput output) {
    final value = output.displayValue;
    return switch (output.type) {
      'datetime' => _formatDateTime(value),
      'boolean' => _formatBoolean(value),
      'number' when output.name == 'sizeBytes' => _formatFileSize(value),
      'number' => _formatNumber(value),
      _ => formatValue(value),
    };
  }

  static String formatValue(Object? value) {
    if (value == null) return LocaleKeys.output_labels_no_value.tr();
    if (value is bool) return _formatBoolean(value);
    if (value is num) return _formatNumber(value);
    if (value is List) return value.map(formatValue).join(' · ');
    if (value is Map) return _formatMap(value);
    return value.toString();
  }

  static String _formatDateTime(Object? value) {
    final dateTime = DateTime.tryParse(value?.toString() ?? '');
    if (dateTime == null) return formatValue(value);
    final local = dateTime.toLocal();
    return '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year}, '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  static String _formatBoolean(Object? value) {
    return (value == true
            ? LocaleKeys.output_labels_yes
            : LocaleKeys.output_labels_no)
        .tr();
  }

  static String _formatNumber(Object? value) {
    if (value is! num) return formatValue(value);
    if (value % 1 == 0) return value.toInt().toString();
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    return formatted.replaceFirst(RegExp(r'0+$'), '');
  }

  static String _formatFileSize(Object? value) {
    if (value is! num) return formatValue(value);
    final units = ['B', 'KB', 'MB', 'GB'];
    var size = value.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    return '${_formatNumber(size)} ${units[index]}';
  }

  static String _formatMap(Map<dynamic, dynamic> value) {
    return value.entries
        .map(
          (entry) =>
              '${labelFor(entry.key.toString())}: ${formatValue(entry.value)}',
        )
        .join(', ');
  }

  static String _humanize(String value) {
    if (value.isEmpty) return LocaleKeys.output_labels_output.tr();
    final spaced = value
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

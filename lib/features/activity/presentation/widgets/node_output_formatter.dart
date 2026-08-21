import 'dart:convert';

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
  static const _labels = <String, String>{
    'value': 'Ergebnis',
    'text': 'Ergebnis',
    'sender': 'Absender',
    'subject': 'Betreff',
    'message': 'Nachricht',
    'receivedAt': 'Empfangen am',
    'recipient': 'Empfänger',
    'channelId': 'Kanal',
    'providerMessageId': 'Nachrichten-ID',
    'fileId': 'Datei-ID',
    'versionId': 'Version',
    'displayName': 'Dateiname',
    'contentType': 'Dateityp',
    'sizeBytes': 'Größe',
    'folderId': 'Ordner-ID',
    'isNewFile': 'Neu angelegt',
  };

  static String labelFor(String name) {
    return _labels[name] ?? _humanize(name);
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
    if (value == null) return 'Keine Angabe';
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
    return value == true ? 'Ja' : 'Nein';
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
    if (value.isEmpty) return 'Ausgabe';
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

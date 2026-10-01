import '../../domain/entities/event_trigger_config.dart';

/// Kurzer, lesbarer Text für das Ziel — für Feld und Trigger-Karte.
String eventTargetLabel(EventTriggerTarget target) {
  return switch (target) {
    AnywhereTarget() => 'Überall',
    FolderTarget() => _folderLabel(target),
    FileTarget() => _nameOrFallback(target.name, 'Datei'),
    ChannelTarget() => _nameOrFallback(target.name, 'Kanal'),
    ConnectorTarget() => _nameOrFallback(target.name, 'Postfach'),
  };
}

String _folderLabel(FolderTarget target) {
  final name = _nameOrFallback(target.name, 'Verzeichnis');
  return target.includeSubfolders ? '$name (mit Unterordnern)' : name;
}

String _nameOrFallback(String name, String fallback) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

/// Platzhalter des Ziel-Feldes passend zur Ereignisquelle.
String eventTargetFieldLabel(EventTargetScope scope) {
  return switch (scope) {
    EventTargetScope.files => 'Wo?',
    EventTargetScope.channel => 'Welcher Kanal?',
    EventTargetScope.mailConnector => 'Welches Postfach?',
    EventTargetScope.none => '',
  };
}

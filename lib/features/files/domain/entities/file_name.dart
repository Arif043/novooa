/// Ein gültiger Dateiname ohne Pfadanteile — dieselben Regeln wie in der
/// Runtime (`FileUpload.name`): 1 bis 255 Zeichen, kein `/` oder `\`, nicht
/// `.` oder `..`.
class FileName {
  const FileName._(this.value);

  static const maximumLength = 255;

  final String value;

  static FileName? tryParse(String input) {
    final name = input.trim();
    if (name.isEmpty || name.length > maximumLength) return null;
    if (name == '.' || name == '..') return null;
    if (name.contains('/') || name.contains(r'\')) return null;
    return FileName._(name);
  }

  /// Name ohne Endung; Dateien wie `.env` haben keine Endung.
  String get baseName {
    final dot = _extensionDot;
    return dot == null ? value : value.substring(0, dot);
  }

  /// Endung samt Punkt (`.xlsx`) oder leer.
  String get extension {
    final dot = _extensionDot;
    return dot == null ? '' : value.substring(dot);
  }

  /// Hängt [suffix] an den Basisnamen, die Endung bleibt: `Bericht (Kopie).pdf`.
  FileName withBaseSuffix(String suffix) {
    return FileName.tryParse('$baseName$suffix$extension') ?? this;
  }

  int? get _extensionDot {
    final dot = value.lastIndexOf('.');
    return dot <= 0 ? null : dot;
  }

  @override
  bool operator ==(Object other) => other is FileName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

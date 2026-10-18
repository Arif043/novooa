import 'package:equatable/equatable.dart';

/// Ein Python-Paket von PyPI, wie es ein Script-Baustein verlangt:
/// `pandas`, `pandas==2.2.3`, `requests[socks]>=2.31,<3`.
///
/// Nur Name, Extras und Versionsangabe — keine URLs, Pfade oder Optionen;
/// dieselbe Regel prüft der Paketdienst. Gleich sind zwei Pakete, wenn ihre
/// [normalized] Form gleich ist (wie `normalizedScriptPackages` im Backend).
class PythonPackage extends Equatable {
  const PythonPackage._(this.spec, this.normalized, this.name);

  /// `null`, wenn [text] keine gültige Paketangabe ist.
  static PythonPackage? parse(String text) {
    final trimmed = text.trim();
    final match = _spec.firstMatch(trimmed);
    if (match == null) return null;
    final name = _normalizedName(match.group(1)!);
    final extras = _extrasOf(match.group(2));
    final version = (match.group(3) ?? '').replaceAll(RegExp(r'\s+'), '');
    return PythonPackage._(trimmed, '$name$extras$version', name);
  }

  /// Die Angabe wie eingegeben; so wird sie gespeichert.
  final String spec;

  /// Feste Form: Name nach PEP 503, Extras sortiert, Version ohne Leerzeichen.
  final String normalized;

  /// Der normalisierte Paketname ohne Extras und Version, z. B. `opencv-python`.
  final String name;

  /// Die feste Form einer Liste, wie sie eine Umgebung kennzeichnet.
  static List<String> normalizedList(Iterable<PythonPackage> packages) {
    return ({for (final package in packages) package.normalized}.toList())
      ..sort();
  }

  @override
  List<Object?> get props => [normalized];
}

const _name = r'[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?';
const _clause = r'(?:===|==|!=|~=|>=|<=|>|<)\s*[A-Za-z0-9.*+!_-]+';
final _spec = RegExp(
  '^($_name)\\s*(\\[\\s*$_name(?:\\s*,\\s*$_name)*\\s*\\])?\\s*'
  '($_clause(?:\\s*,\\s*$_clause)*)?\$',
);

String _normalizedName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[-_.]+'), '-');

String _extrasOf(String? extras) {
  if (extras == null) return '';
  final names = {
    for (final extra in extras.substring(1, extras.length - 1).split(','))
      if (extra.trim().isNotEmpty) _normalizedName(extra.trim()),
  }.toList()..sort();
  return names.isEmpty ? '' : '[${names.join(',')}]';
}

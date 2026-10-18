import 'python_standard_library.dart';

/// Findet die obersten Module, die ein Script importiert und die nicht zur
/// Standardbibliothek gehören — Kandidaten für Pakete.
///
/// Erkannt werden `import a, b.c as d` und `from a.b import c` am
/// Zeilenanfang (auch eingerückt); relative Imports, Kommentare und private
/// Module (`_x`) zählen nicht.
class PythonImportScanner {
  const PythonImportScanner();

  List<String> call(String script) {
    final modules = <String>[];
    for (final line in script.split('\n')) {
      for (final module in _modulesOf(line)) {
        if (_isCandidate(module) && !modules.contains(module)) {
          modules.add(module);
        }
      }
    }
    return modules;
  }

  Iterable<String> _modulesOf(String line) {
    final code = line.split('#').first;
    final from = _from.firstMatch(code);
    if (from != null) return [_topLevel(from.group(1)!)];
    final plain = _import.firstMatch(code);
    if (plain == null) return const [];
    return plain
        .group(1)!
        .split(',')
        .map((part) => _topLevel(part.trim().split(RegExp(r'\s+')).first));
  }

  bool _isCandidate(String module) =>
      module.isNotEmpty &&
      !module.startsWith('_') &&
      !pythonStandardLibraryModules.contains(module);

  String _topLevel(String module) => module.split('.').first;
}

final _from = RegExp(r'^\s*from\s+([A-Za-z_][\w.]*)\s+import\b');
final _import = RegExp(
  r'^\s*import\s+([A-Za-z_][\w.]*(?:\s+as\s+\w+)?(?:\s*,\s*[A-Za-z_][\w.]*(?:\s+as\s+\w+)?)*)',
);

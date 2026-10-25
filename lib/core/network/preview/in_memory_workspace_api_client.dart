import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import 'in_memory_workspace_store.dart';

/// Ersetzt die Runtime in der UI-Vorschau: beantwortet die `/v1`-Aufrufe der
/// Standalone-Repositories aus einem [InMemoryWorkspaceStore].
///
/// Bewusst generisch: Nur Lizenz und Sitzung haben feste Antworten, alles
/// andere folgt der REST-Konvention der Runtime. Fachlogik (Ausführung,
/// KI-Agent, Importe) gibt es hier nicht — sie liefert leere Ergebnisse.
class InMemoryWorkspaceApiClient extends WorkspaceApiClient {
  InMemoryWorkspaceApiClient(this.store);

  final InMemoryWorkspaceStore store;

  static const _license = {'state': 'active'};

  @override
  Future<Map<String, Object?>> get(String path) async {
    final segments = _segments(path);
    if (path.startsWith('/v1/license')) return _license;
    return switch (segments) {
      [final collection] => {
        ...store.singleton(collection),
        'items': store.list(collection),
      },
      [final collection, final id] => _documentOrEmptyList(collection, id),
      _ => {'items': const <Object?>[]},
    };
  }

  Map<String, Object?> _documentOrEmptyList(String collection, String id) {
    final matches = store.list(collection).where((doc) => doc['id'] == id);
    return matches.isEmpty ? {'items': const <Object?>[]} : matches.first;
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    if (path.startsWith('/v1/license')) return _license;
    return switch (_segments(path)) {
      [final collection] => store.create(collection, body),
      _ => const {},
    };
  }

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async {
    return switch (_segments(path)) {
      [final name] => store.saveSingleton(name, body),
      [final collection, final id, ...] => store.upsert(collection, id, body),
      _ => const {},
    };
  }

  @override
  Future<Map<String, Object?>> delete(String path) async {
    if (_segments(path) case [final collection, final id]) {
      store.remove(collection, Uri.decodeComponent(id));
    }
    return const {};
  }

  /// Datei-Uploads werden verworfen; die Vorschau speichert keine Inhalte.
  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) async {
    await body.drain<void>();
    return const {};
  }

  List<String> _segments(String path) {
    final segments = Uri.parse(path).pathSegments;
    return segments.isNotEmpty && segments.first == 'v1'
        ? segments.sublist(1)
        : segments;
  }
}

import 'dart:async';

/// Flüchtiger Datenspeicher der UI-Vorschau. Bildet die REST-Konvention der
/// Runtime nach: Sammlungen (`/v1/<name>`) mit Dokumenten je `id` sowie
/// Einzeldokumente (`PUT /v1/<name>`), etwa Einstellungen.
class InMemoryWorkspaceStore {
  final Map<String, Map<String, Map<String, Object?>>> _collections = {};
  final Map<String, Map<String, Object?>> _singletons = {};
  final StreamController<String> _changes = StreamController.broadcast();
  int _sequence = 0;

  /// Name der Sammlung, die sich geändert hat — entspricht dem Realtime-Topic.
  Stream<String> get changes => _changes.stream;

  List<Map<String, Object?>> list(String collection) =>
      (_collections[collection]?.values ?? const []).toList(growable: false);

  Map<String, Object?> singleton(String name) => _singletons[name] ?? const {};

  Map<String, Object?> create(String collection, Map<String, Object?> body) {
    final id = (body['id'] as String?) ?? '$collection-${++_sequence}';
    return upsert(collection, id, body);
  }

  Map<String, Object?> upsert(
    String collection,
    String id,
    Map<String, Object?> body,
  ) {
    final now = DateTime.now().toUtc().toIso8601String();
    final documents = _collections.putIfAbsent(collection, () => {});
    final existing = documents[id];
    final document = {
      'createdAt': now,
      ...?existing,
      ...body,
      'id': id,
      'updatedAt': now,
    };
    documents[id] = document;
    _changes.add(collection);
    return document;
  }

  Map<String, Object?> saveSingleton(String name, Map<String, Object?> body) {
    final document = {...singleton(name), ...body};
    _singletons[name] = document;
    _changes.add(name);
    return document;
  }

  void remove(String collection, String id) {
    _collections[collection]?.remove(id);
    _changes.add(collection);
  }

  Future<void> close() => _changes.close();
}

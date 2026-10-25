import 'dart:async';
import 'dart:typed_data';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import 'in_memory_workspace_store.dart';

/// Gibt Änderungen des Speichers als Realtime-Signal weiter, damit offene
/// Listen wie mit einer echten Runtime sofort aktualisiert werden.
class InMemoryWorkspaceRealtimeChannel implements WorkspaceRealtimeChannel {
  InMemoryWorkspaceRealtimeChannel(this._store);

  final InMemoryWorkspaceStore _store;

  @override
  Stream<void> watch(String topic) =>
      _store.changes.where((changed) => changed == topic);

  @override
  Future<void> close() async {}
}

/// Exporte und Importe liefern in der Vorschau leere Ergebnisse.
class InMemoryWorkspaceBinaryClient implements WorkspaceBinaryClient {
  const InMemoryWorkspaceBinaryClient();

  @override
  Future<Uint8List> postForBytes(
    String path,
    Map<String, Object?> body,
  ) async => Uint8List(0);

  @override
  Future<Map<String, Object?>> postBytes(
    String path, {
    required Uint8List body,
    required String contentType,
  }) async => const {};
}

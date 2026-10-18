import '../entities/knowledge_note.dart';

/// Welche Notizen ein Baustein sieht, an dem [startId] hängt: die Notiz
/// selbst und per Breitensuche ihre ausgehenden Links, bis [maxDepth] Ebenen
/// und höchstens [maxNotes] Notizen. Backlinks zählen nicht.
///
/// Dieselben Regeln wie beim Run (`knowledge-note-workspace.ts` im Backend);
/// ändern sich dort die Grenzen, müssen sie hier mitziehen.
class KnowledgeNoteReach {
  const KnowledgeNoteReach({this.maxDepth = 5, this.maxNotes = 50});

  final int maxDepth;
  final int maxNotes;

  /// Notiz-ID → Ebene (0 = die Notiz selbst), in Reihenfolge der Suche.
  Map<String, int> call(String startId, List<KnowledgeNote> notes) {
    final byId = {for (final note in notes) note.id: note};
    if (!byId.containsKey(startId)) return const {};
    final depths = <String, int>{startId: 0};
    final queue = [startId];
    for (
      var index = 0;
      index < queue.length && depths.length < maxNotes;
      index++
    ) {
      final id = queue[index];
      final depth = depths[id]!;
      if (depth == maxDepth) continue;
      for (final target in byId[id]!.outgoingLinks) {
        if (depths.length >= maxNotes) break;
        if (!byId.containsKey(target) || depths.containsKey(target)) continue;
        depths[target] = depth + 1;
        queue.add(target);
      }
    }
    return depths;
  }
}

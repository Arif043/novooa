import 'package:syscat2/features/files/domain/entities/team_folder.dart';

typedef FolderTreeEntry = ({TeamFolder folder, int depth});

/// Ordnet Verzeichnisse als Baum in Anzeigereihenfolge (Eltern vor Kindern,
/// je Ebene alphabetisch). Verzeichnisse mit unbekanntem Elternteil landen
/// auf oberster Ebene; Zyklen werden durch die Besuchsliste abgefangen.
List<FolderTreeEntry> flattenFolderTree(List<TeamFolder> folders) {
  final knownIds = {for (final folder in folders) folder.id};
  final entries = <FolderTreeEntry>[];
  final visited = <String>{};

  void visit(TeamFolder folder, int depth) {
    if (!visited.add(folder.id)) return;
    entries.add((folder: folder, depth: depth));
    for (final child in _childrenOf(folder.id, folders)) {
      visit(child, depth + 1);
    }
  }

  final roots = folders.where(
    (folder) =>
        folder.parentFolderId == null ||
        !knownIds.contains(folder.parentFolderId),
  );
  for (final root in _sortedByName(roots)) {
    visit(root, 0);
  }
  return entries;
}

/// Lesbarer Pfad wie `Berichte / 2026`; `null`, wenn das Verzeichnis nicht
/// (mehr) existiert.
String? folderPathLabel(String folderId, List<TeamFolder> folders) {
  final byId = {for (final folder in folders) folder.id: folder};
  final names = <String>[];
  var current = byId[folderId];
  while (current != null && names.length <= folders.length) {
    names.insert(0, current.name);
    current = byId[current.parentFolderId];
  }
  return names.isEmpty ? null : names.join(' / ');
}

List<TeamFolder> _childrenOf(String parentId, List<TeamFolder> folders) {
  return _sortedByName(
    folders.where((folder) => folder.parentFolderId == parentId),
  );
}

List<TeamFolder> _sortedByName(Iterable<TeamFolder> folders) {
  return folders.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

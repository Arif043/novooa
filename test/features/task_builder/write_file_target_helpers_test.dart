import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_folder_tree.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_kind_filter.dart';

void main() {
  group('WriteFileKindFilter', () {
    final files = [
      _file('notiz.md', 'text/markdown'),
      _file('foto.png', 'image/png'),
      _file('clip.mp4', 'video/mp4'),
    ];

    test('ordnet Dateien ihrer Kategorie zu', () {
      expect(WriteFileKindFilter.text.matches(files[0]), isTrue);
      expect(WriteFileKindFilter.image.matches(files[1]), isTrue);
      expect(WriteFileKindFilter.video.matches(files[2]), isTrue);
      expect(WriteFileKindFilter.image.matches(files[0]), isFalse);
    });

    test('bietet nur Kategorien mit Dateien an', () {
      expect(WriteFileKindFilter.availableFor(files), [
        WriteFileKindFilter.all,
        WriteFileKindFilter.text,
        WriteFileKindFilter.image,
        WriteFileKindFilter.video,
      ]);
    });

    testWidgets('meldet die gewählte Kategorie', (tester) async {
      WriteFileKindFilter? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WriteFileKindFilterChips(
              filters: WriteFileKindFilter.availableFor(files),
              selected: WriteFileKindFilter.all,
              onSelected: (filter) => selected = filter,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Bilder'));

      expect(selected, WriteFileKindFilter.image);
    });
  });

  group('Ordnerbaum', () {
    final folders = [
      _folder('b', 'Berichte'),
      _folder('a', 'Archiv'),
      _folder('b1', '2026', parent: 'b'),
    ];

    test('sortiert Kinder unter ihre Eltern', () {
      final entries = flattenFolderTree(folders);

      expect(entries.map((entry) => entry.folder.id), ['a', 'b', 'b1']);
      expect(entries.map((entry) => entry.depth), [0, 0, 1]);
    });

    test('bildet den Pfad eines Verzeichnisses', () {
      expect(folderPathLabel('b1', folders), 'Berichte / 2026');
      expect(folderPathLabel('fehlt', folders), isNull);
    });

    test('überlebt zyklische Eltern-Beziehungen', () {
      final cyclic = [_folder('x', 'X', parent: 'y'), _folder('y', 'Y', parent: 'x')];

      expect(flattenFolderTree(cyclic), isEmpty);
      expect(folderPathLabel('x', cyclic), isNotNull);
    });
  });
}

NodeAttachment _file(String name, String contentType) {
  return NodeAttachment(
    id: name,
    storagePath: name,
    generation: '1',
    displayName: name,
    contentType: contentType,
    sizeBytes: 1,
  );
}

TeamFolder _folder(String id, String name, {String? parent}) {
  return TeamFolder(
    id: id,
    teamId: const TeamId('team'),
    ownerUid: 'u',
    name: name,
    parentFolderId: parent,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

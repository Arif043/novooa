import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/presentation/cubits/files_state.dart';
import 'package:syscat2/features/files/presentation/widgets/files_initial_state.dart';

void main() {
  test('der Anfangszustand gilt nur ohne Dateien und Ordner', () {
    expect(const FilesState(status: FilesLoadStatus.ready).isInitial, isTrue);
    expect(const FilesState().isInitial, isFalse, reason: 'lädt noch');
    expect(
      FilesState(
        status: FilesLoadStatus.ready,
        folders: [
          TeamFolder(
            id: 'f1',
            teamId: const TeamId('t'),
            ownerUid: 'u',
            name: 'Ablage',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      ).isInitial,
      isFalse,
    );
  });

  testWidgets('zeigt eine zentrale Einladung mit Hochladen als Hauptaktion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FilesInitialState(isUploading: false)),
      ),
    );

    expect(find.text('Ein Zuhause für deine Dateien'), findsOneWidget);
    expect(find.text('Erste Datei hochladen'), findsOneWidget);
    expect(find.text('Neuer Ordner'), findsOneWidget);
  });
}

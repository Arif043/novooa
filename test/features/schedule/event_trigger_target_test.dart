import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/files/domain/entities/team_file.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/infrastructure/models/event_trigger_config_mapper.dart';
import 'package:syscat2/features/schedule/presentation/cubits/event_target_options_state.dart';
import 'package:syscat2/features/schedule/presentation/widgets/event_channel_target_picker.dart';
import 'package:syscat2/features/schedule/presentation/widgets/event_file_kind_chips.dart';
import 'package:syscat2/features/schedule/presentation/widgets/event_file_target_picker.dart';
import 'package:syscat2/features/schedule/presentation/widgets/schedule_formatters.dart';

void main() {
  group('EventTriggerConfigMapper', () {
    test('schreibt und liest Ziel, Dateitypen und Filter', () {
      const config = EventTriggerConfig(
        source: EventTriggerSource.fileCreated,
        target: FolderTarget(
          id: 'f1',
          name: 'Berichte',
          includeSubfolders: false,
        ),
        fileKinds: {EventFileKind.image, EventFileKind.pdf},
        filter: ' rechnung ',
      );

      final document = EventTriggerConfigMapper.toDocument(config);
      final restored = EventTriggerConfigMapper.fromDocument(document)!;

      expect(document['filter'], 'rechnung');
      expect(restored.source, EventTriggerSource.fileCreated);
      final target = restored.target as FolderTarget;
      expect(
        (target.id, target.name, target.includeSubfolders),
        ('f1', 'Berichte', false),
      );
      expect(restored.fileKinds, {EventFileKind.image, EventFileKind.pdf});
    });

    test('ohne oder mit unvollständigem Ziel gilt „überall“', () {
      final restored = EventTriggerConfigMapper.fromDocument({
        'source': 'fileDeleted',
        'target': {'kind': 'folder'},
      })!;

      expect(restored.target, isA<AnywhereTarget>());
      expect(restored.fileKinds, isEmpty);
    });

    test('unbekannte Dateitypen werden ignoriert', () {
      final restored = EventTriggerConfigMapper.fromDocument({
        'source': 'fileCreated',
        'fileKinds': ['image', 'quatsch'],
      })!;

      expect(restored.fileKinds, {EventFileKind.image});
    });
  });

  group('eventLabel', () {
    test('fasst Quelle, Ziel, Dateitypen und Filter zusammen', () {
      const config = EventTriggerConfig(
        source: EventTriggerSource.fileCreated,
        target: FolderTarget(id: 'f1', name: 'Berichte / 2026'),
        fileKinds: {EventFileKind.image},
        filter: 'foto',
      );

      expect(
        eventLabel(config),
        'Datei erstellt · Berichte / 2026 (mit Unterordnern) · Bilder · „foto“',
      );
    });

    test(
      'zeigt ohne Ziel nur die Quelle und ignoriert Typen bei Einzeldatei',
      () {
        expect(
          eventLabel(
            const EventTriggerConfig(
              source: EventTriggerSource.webhookReceived,
            ),
          ),
          'Webhook empfangen',
        );
        expect(
          eventLabel(
            const EventTriggerConfig(
              source: EventTriggerSource.fileDeleted,
              target: FileTarget(id: 'x', name: 'a.pdf'),
              fileKinds: {EventFileKind.text},
            ),
          ),
          'Datei gelöscht · a.pdf',
        );
      },
    );
  });

  testWidgets('Dateityp-Chips schalten Kategorien um', (tester) async {
    var selected = <EventFileKind>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => EventFileKindChips(
              selected: selected,
              onChanged: (kinds) => setState(() => selected = kinds),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Bilder'));
    await tester.pump();
    await tester.tap(find.text('PDF'));
    await tester.pump();
    await tester.tap(find.text('Bilder'));
    await tester.pump();

    expect(selected, {EventFileKind.pdf});
  });

  testWidgets('Datei-Zielwahl: Verzeichnis wählen und Unterordner umschalten', (
    tester,
  ) async {
    EventTriggerTarget? selected = EventTriggerTarget.anywhere;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => EventFileTargetPicker(
            options: _options(),
            selected: selected!,
            onChanged: (target) => setState(() => selected = target),
          ),
        ),
      ),
    );

    await tester.tap(find.text('2026'));
    await tester.pump();

    final folder = selected as FolderTarget;
    expect(
      (folder.id, folder.name, folder.includeSubfolders),
      ('b1', 'Berichte / 2026', true),
    );

    await tester.tap(find.text('Unterordner einbeziehen'));
    await tester.pump();

    expect((selected as FolderTarget).includeSubfolders, isFalse);
  });

  testWidgets('Datei-Zielwahl: einzelne Datei suchen und wählen', (
    tester,
  ) async {
    EventTriggerTarget? selected = EventTriggerTarget.anywhere;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => EventFileTargetPicker(
            options: _options(),
            selected: selected!,
            onChanged: (target) => setState(() => selected = target),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Datei'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'bilanz');
    await tester.pump();

    expect(find.text('Rechnung.pdf'), findsNothing);
    await tester.tap(find.text('Bilanz.xlsx'));
    await tester.pump();

    expect((selected as FileTarget).id, 'file-2');
  });

  testWidgets('Kanal-Zielwahl zeigt nur passende, aktive Kanäle', (
    tester,
  ) async {
    EventTriggerTarget? selected;
    await tester.pumpWidget(
      _host(
        EventChannelTargetPicker(
          source: EventTriggerSource.whatsappMessageReceived,
          options: _options(),
          selected: EventTriggerTarget.anywhere,
          onChanged: (target) => selected = target,
        ),
      ),
    );

    expect(find.text('Support WhatsApp'), findsOneWidget);
    expect(find.text('Support SMS'), findsNothing);
    expect(find.text('Altes WhatsApp'), findsNothing);

    await tester.tap(find.text('Support WhatsApp'));

    expect((selected as ChannelTarget).id, 'wa-1');
  });

  testWidgets('Postfach-Zielwahl liefert die Connector-ID', (tester) async {
    EventTriggerTarget? selected;
    await tester.pumpWidget(
      _host(
        EventChannelTargetPicker(
          source: EventTriggerSource.emailReceived,
          options: _options(),
          selected: EventTriggerTarget.anywhere,
          onChanged: (target) => selected = target,
        ),
      ),
    );

    await tester.tap(find.text('Info-Postfach'));

    expect((selected as ConnectorTarget).id, 'connector-1');
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(height: 600, child: child)),
  );
}

EventTargetOptionsState _options() {
  return EventTargetOptionsState(
    status: EventTargetOptionsStatus.ready,
    folders: [
      _folder('b', 'Berichte'),
      _folder('b1', '2026', parent: 'b'),
    ],
    files: [
      _file('file-1', 'Rechnung.pdf'),
      _file('file-2', 'Bilanz.xlsx', folder: 'b1'),
    ],
    channels: [
      _channel('wa-1', 'Support WhatsApp', CommunicationChannelKind.whatsapp),
      _channel(
        'wa-2',
        'Altes WhatsApp',
        CommunicationChannelKind.whatsapp,
        status: CommunicationChannelStatus.disabled,
      ),
      _channel('sms-1', 'Support SMS', CommunicationChannelKind.sms),
      _channel(
        'mail-1',
        'Info-Postfach',
        CommunicationChannelKind.email,
        connectorId: 'connector-1',
      ),
    ],
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

TeamFile _file(String id, String name, {String? folder}) {
  return TeamFile(
    id: id,
    teamId: const TeamId('team'),
    ownerUid: 'u',
    displayName: name,
    storagePath: name,
    currentVersionId: 'v',
    contentType: 'application/pdf',
    sizeBytes: 1,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    currentVersionCreatedAt: DateTime(2026),
    folderId: folder,
  );
}

CommunicationChannel _channel(
  String id,
  String label,
  CommunicationChannelKind kind, {
  CommunicationChannelStatus status = CommunicationChannelStatus.active,
  String? connectorId,
}) {
  return CommunicationChannel(
    id: id,
    teamId: const TeamId('team'),
    createdByUid: 'u',
    provider: CommunicationProvider.twilio,
    kind: kind,
    label: label,
    address: '+49',
    status: status,
    capabilities: const ChannelCapabilities(inbound: true, outbound: true),
    connectorId: connectorId,
  );
}

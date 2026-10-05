import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/infrastructure/models/event_trigger_config_mapper.dart';
import 'package:syscat2/features/schedule/presentation/widgets/event_trigger_form_controls.dart';
import 'package:syscat2/features/schedule/presentation/widgets/plugin_trigger_picker.dart';
import 'package:syscat2/features/schedule/presentation/widgets/schedule_formatters.dart';

const _manifest = PluginManifest(
  id: 'hallo',
  version: '1.0.0',
  name: 'Hallo-Plugin',
  description: '',
  triggers: [
    PluginTriggerDefinition(
      type: 'tick',
      label: 'Jede Minute',
      description: 'Löst regelmäßig aus.',
      settings: [
        PluginField(
          key: 'prefix',
          label: 'Präfix',
          kind: PluginFieldKind.text,
          defaultValue: 'Tick',
        ),
      ],
    ),
  ],
);

const _selection = PluginTriggerSelection(
  pluginId: 'hallo',
  type: 'tick',
  label: 'Hallo-Plugin · Jede Minute',
  settings: {'prefix': 'Tick', 'times': 2, 'loud': true},
);

void main() {
  group('EventTriggerConfig mit Plugin', () {
    test('wird verlustfrei gespeichert und gelesen', () {
      const config = EventTriggerConfig(
        source: EventTriggerSource.plugin,
        plugin: _selection,
      );

      final document = EventTriggerConfigMapper.toDocument(config);
      final restored = EventTriggerConfigMapper.fromDocument(document)!;

      expect(document['source'], 'plugin');
      expect(restored.source, EventTriggerSource.plugin);
      expect(restored.plugin!.pluginId, 'hallo');
      expect(restored.plugin!.type, 'tick');
      expect(restored.plugin!.label, 'Hallo-Plugin · Jede Minute');
      expect(restored.plugin!.settings, _selection.settings);
    });

    test('andere Quellen schreiben kein Plugin-Feld', () {
      final document = EventTriggerConfigMapper.toDocument(
        const EventTriggerConfig(source: EventTriggerSource.fileCreated),
      );

      expect(document.containsKey('plugin'), isFalse);
    });

    test('ein Plugin-Ereignis ohne Auswahl ist ungültig', () {
      expect(
        const EventTriggerConfig(source: EventTriggerSource.plugin).isValid,
        isFalse,
      );
      expect(
        const EventTriggerConfig(
          source: EventTriggerSource.plugin,
          plugin: _selection,
        ).isValid,
        isTrue,
      );
      expect(
        const EventTriggerConfig(source: EventTriggerSource.fileDeleted).isValid,
        isTrue,
      );
    });

    test('die Trigger-Karte nennt Plugin und Trigger', () {
      expect(
        eventLabel(
          const EventTriggerConfig(
            source: EventTriggerSource.plugin,
            plugin: _selection,
          ),
        ),
        'Hallo-Plugin · Jede Minute',
      );
    });
  });

  group('EventTriggerControls', () {
    Future<List<PluginTriggerSelection>> pump(
      WidgetTester tester, {
      required EventTriggerSource source,
      List<PluginManifest> manifests = const [_manifest],
      PluginTriggerSelection? plugin,
    }) async {
      final picked = <PluginTriggerSelection>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EventTriggerControls(
                source: source,
                target: EventTriggerTarget.anywhere,
                fileKinds: const {},
                filterController: TextEditingController(),
                onSourceChanged: (_) {},
                onTargetChanged: (_) {},
                onFileKindsChanged: (_) {},
                pluginOptions: pluginTriggerOptions(manifests),
                plugin: plugin,
                onPluginChanged: picked.add,
              ),
            ),
          ),
        ),
      );
      return picked;
    }

    testWidgets('ohne Plugin-Trigger fehlt die Quelle „Plugin“', (tester) async {
      await pump(
        tester,
        source: EventTriggerSource.emailReceived,
        manifests: const [],
      );

      await tester.tap(find.byType(DropdownButtonFormField<EventTriggerSource>));
      await tester.pumpAndSettle();

      expect(find.text('Ereignis eines Plugins'), findsNothing);
      expect(find.text('Datei erstellt'), findsWidgets);
    });

    testWidgets('mit Plugin-Trigger ist die Quelle wählbar', (tester) async {
      await pump(tester, source: EventTriggerSource.emailReceived);

      await tester.tap(find.byType(DropdownButtonFormField<EventTriggerSource>));
      await tester.pumpAndSettle();

      expect(find.text('Ereignis eines Plugins'), findsWidgets);
    });

    testWidgets('wählt einen Trigger und setzt die Standardwerte seiner Felder', (tester) async {
      final picked = await pump(tester, source: EventTriggerSource.plugin);
      expect(find.text('Weitere Optionen'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<PluginTriggerOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hallo-Plugin · Jede Minute').last);
      await tester.pumpAndSettle();

      expect(picked.single.pluginId, 'hallo');
      expect(picked.single.type, 'tick');
      expect(picked.single.label, 'Hallo-Plugin · Jede Minute');
      expect(picked.single.settings, {'prefix': 'Tick'});
    });

    testWidgets('zeigt die Einstellungen des gewählten Triggers und meldet Änderungen', (tester) async {
      final picked = await pump(
        tester,
        source: EventTriggerSource.plugin,
        plugin: const PluginTriggerSelection(
          pluginId: 'hallo',
          type: 'tick',
          label: 'Hallo-Plugin · Jede Minute',
          settings: {'prefix': 'Tick'},
        ),
      );

      expect(find.text('Löst regelmäßig aus.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Präfix'), 'Tack');

      expect(picked.single.settings, {'prefix': 'Tack'});
    });
  });
}

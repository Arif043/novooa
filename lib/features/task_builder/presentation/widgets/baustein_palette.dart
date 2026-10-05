import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/runtime/plugins_availability.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_registry_cubit.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugin_icons.dart';
import 'plugin_baustein_choices.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/workflow_primitive_labels.dart';

class BausteinChoice {
  const BausteinChoice(this.primitive, {this.kind, this.plugin, this.pluginIcon});
  final WorkflowPrimitive primitive;
  final ChannelEventKind? kind;

  /// Gesetzt bei Bausteinen, die ein Plugin liefert.
  final PluginNodeSeed? plugin;
  final String? pluginIcon;

  IconData get icon => plugin == null
      ? bausteinIcon(primitive)
      : pluginIconFor(pluginIcon);

  String get label => plugin != null
      ? plugin!.title
      : kind == null
      ? primitive.label
      : '${switch (kind!) {
          ChannelEventKind.email => 'E-Mail',
          ChannelEventKind.whatsapp => 'WhatsApp',
          ChannelEventKind.sms => 'SMS',
        }} ${primitive == WorkflowPrimitive.readChannelEvent ? 'lesen' : 'senden'}';
}

const bausteinGroups = <String, List<BausteinChoice>>{
  'Daten': [
    BausteinChoice(.documentLookup),
    BausteinChoice(.saveDocument),
    BausteinChoice(.tableFromCollection),
    BausteinChoice(.stringInput),
    BausteinChoice(.readFile),
    BausteinChoice(.writeFile),
  ],
  'Logik': [
    BausteinChoice(.conditional),
    BausteinChoice(.forEach),
    BausteinChoice(.script),
  ],
  'Künstliche Intelligenz': [
    BausteinChoice(.prompt),
    BausteinChoice(.iterativeRefinement),
    BausteinChoice(.modelInference),
    BausteinChoice(.textToSpeech),
    BausteinChoice(.speechToText),
  ],
  'Interaktion': [
    BausteinChoice(.humanApproval),
    BausteinChoice(.dialogInput),
    BausteinChoice(.mediaInput),
  ],
  'Kommunikation': [
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.email),
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.whatsapp),
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.sms),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.email),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.whatsapp),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.sms),
    BausteinChoice(.notificationSend),
  ],
};

IconData bausteinIcon(WorkflowPrimitive primitive) => switch (primitive) {
  .stringInput => CupertinoIcons.textformat,
  .script => CupertinoIcons.chevron_left_slash_chevron_right,
  .prompt => CupertinoIcons.wand_stars,
  .conditional => CupertinoIcons.arrow_branch,
  .iterativeRefinement => CupertinoIcons.paintbrush,
  .writeFile => CupertinoIcons.doc_plaintext,
  .readFile => CupertinoIcons.doc_text_search,
  .readEmail || .readChannelEvent => CupertinoIcons.mail,
  .sendChannelMessage => Icons.send_outlined,
  .notificationSend => CupertinoIcons.bell,
  .humanApproval => CupertinoIcons.person_alt,
  .dialogInput => CupertinoIcons.line_horizontal_3,
  .mediaInput => CupertinoIcons.camera,
  .modelInference => CupertinoIcons.rectangle,
  .textToSpeech => CupertinoIcons.speaker_2,
  .speechToText => CupertinoIcons.waveform,
  .forEach => CupertinoIcons.arrow_2_squarepath,
  .documentLookup => CupertinoIcons.search,
  .saveDocument => CupertinoIcons.archivebox,
  .tableFromCollection => CupertinoIcons.table,
  .toolCall => Icons.build_outlined,
  .validation => Icons.fact_check_outlined,
  .plugin => Icons.extension_outlined,
};

class BausteinPalette extends StatefulWidget {
  const BausteinPalette({super.key, required this.onAdd});
  final ValueChanged<BausteinChoice> onAdd;
  @override
  State<BausteinPalette> createState() => _BausteinPaletteState();
}

class _BausteinPaletteState extends State<BausteinPalette> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final manifests = pluginsAvailable()
        ? context.watch<PluginRegistryCubit>().state
        : const <PluginManifest>[];
    final groups = {
      for (final group in {
        ...bausteinGroups,
        ...pluginBausteinGroups(manifests),
      }.entries)
        group.key: group.value
            .where((choice) => choice.label.toLowerCase().contains(_query))
            .toList(),
    };
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Bausteine',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  labelText: 'Bausteine suchen',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  if (groups.values.every((items) => items.isEmpty))
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Keine Bausteine gefunden.'),
                    ),
                  for (final group in groups.entries)
                    if (group.value.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                        child: Text(
                          group.key.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      for (final choice in group.value)
                        Draggable<BausteinChoice>(
                          data: choice,
                          feedback: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(choice.label),
                            ),
                          ),
                          child: ListTile(
                            minTileHeight: 52,
                            horizontalTitleGap: 12,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                choice.icon,
                                size: 20,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              choice.label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            onTap: () => widget.onAdd(choice),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

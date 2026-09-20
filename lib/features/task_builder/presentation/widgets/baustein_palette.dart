import 'package:flutter/material.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/workflow_primitive_labels.dart';

class BausteinChoice {
  const BausteinChoice(this.primitive, {this.kind});
  final WorkflowPrimitive primitive;
  final ChannelEventKind? kind;

  String get label => kind == null
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
  ],
};

IconData bausteinIcon(WorkflowPrimitive primitive) => switch (primitive) {
  .stringInput => Icons.text_fields,
  .script => Icons.code,
  .prompt => Icons.auto_awesome_outlined,
  .conditional => Icons.call_split,
  .iterativeRefinement => Icons.autorenew,
  .writeFile => Icons.note_add_outlined,
  .readFile => Icons.file_open_outlined,
  .readEmail || .readChannelEvent => Icons.mark_email_read_outlined,
  .sendChannelMessage => Icons.send_outlined,
  .humanApproval => Icons.verified_user_outlined,
  .dialogInput => Icons.dynamic_form_outlined,
  .mediaInput => Icons.add_a_photo_outlined,
  .modelInference => Icons.model_training_outlined,
  .forEach => Icons.repeat,
  .documentLookup => Icons.search,
  .saveDocument => Icons.save_outlined,
  .toolCall => Icons.build_outlined,
  .validation => Icons.fact_check_outlined,
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
    final groups = {
      for (final group in bausteinGroups.entries)
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Bausteine suchen …',
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
                          group.key,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
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
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: Icon(
                              bausteinIcon(choice.primitive),
                              size: 22,
                            ),
                            title: Text(choice.label),
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

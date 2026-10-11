import 'package:easy_localization/easy_localization.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_anchor.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/runtime/connections_availability.dart';
import 'package:syscat2/core/runtime/webhooks_availability.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/workflow_primitive_labels.dart';
import '../plugin_node_module.dart';

class BausteinChoice {
  const BausteinChoice(this.primitive, {this.kind}) : pluginTypeId = null;

  /// Eintrag für einen Baustein, den ein Plugin mitbringt.
  BausteinChoice.plugin(PluginNodeModule module)
    : primitive = WorkflowPrimitive.plugin,
      kind = null,
      pluginTypeId = module.typeId;

  final WorkflowPrimitive primitive;
  final ChannelEventKind? kind;
  final String? pluginTypeId;

  PluginNodeModule? get _module =>
      pluginTypeId == null ? null : PluginNodeModules.byTypeId(pluginTypeId!);

  IconData get icon {
    final module = _module;
    if (module != null) return module.icon;
    final channelKind = kind;
    return channelKind == null
        ? bausteinIcon(primitive)
        : _channelIcon(channelKind);
  }

  /// Anbieter, die noch nicht angebunden sind, erscheinen deaktiviert.
  bool get isAvailable => kind?.isAvailable ?? true;

  String get label {
    final module = _module;
    if (module != null) return module.title;
    final channelKind = kind;
    if (channelKind == null) return primitive.label;
    final isRead = primitive == WorkflowPrimitive.readChannelEvent;
    return switch (channelKind) {
      ChannelEventKind.email =>
        isRead
            ? LocaleKeys.task_builder_channels_email_read_title.tr()
            : LocaleKeys.task_builder_channels_email_send_title.tr(),
      ChannelEventKind.whatsapp =>
        isRead
            ? LocaleKeys.task_builder_channels_whatsapp_read_title.tr()
            : LocaleKeys.task_builder_channels_whatsapp_send_title.tr(),
      ChannelEventKind.sms =>
        isRead
            ? LocaleKeys.task_builder_channels_sms_read_title.tr()
            : LocaleKeys.task_builder_channels_sms_send_title.tr(),
      ChannelEventKind.telegram =>
        isRead
            ? LocaleKeys.task_builder_channels_telegram_read_title.tr()
            : LocaleKeys.task_builder_channels_telegram_send_title.tr(),
      ChannelEventKind.instagram =>
        isRead
            ? LocaleKeys.task_builder_channels_instagram_read_title.tr()
            : LocaleKeys.task_builder_channels_instagram_send_title.tr(),
    };
  }
}

const bausteinGroups = <String, List<BausteinChoice>>{
  LocaleKeys.task_builder_palette_groups_data: [
    BausteinChoice(.documentLookup),
    BausteinChoice(.saveDocument),
    BausteinChoice(.tableFromCollection),
    BausteinChoice(.stringInput),
    BausteinChoice(.readFile),
    BausteinChoice(.writeFile),
  ],
  LocaleKeys.task_builder_palette_groups_logic: [
    BausteinChoice(.conditional),
    BausteinChoice(.forEach),
    BausteinChoice(.script),
  ],
  LocaleKeys.task_builder_palette_groups_ai: [
    BausteinChoice(.prompt),
    BausteinChoice(.iterativeRefinement),
    BausteinChoice(.modelInference),
    BausteinChoice(.textToSpeech),
    BausteinChoice(.speechToText),
  ],
  LocaleKeys.task_builder_palette_groups_interaction: [
    BausteinChoice(.humanApproval),
    BausteinChoice(.dialogInput),
    BausteinChoice(.mediaInput),
  ],
  LocaleKeys.task_builder_palette_groups_external: [
    BausteinChoice(.httpRequest),
    BausteinChoice(.readWebhook),
  ],
  LocaleKeys.task_builder_palette_groups_communication: [
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.email),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.email),
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.whatsapp),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.whatsapp),
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.sms),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.sms),
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.telegram),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.telegram),
    BausteinChoice(.readChannelEvent, kind: ChannelEventKind.instagram),
    BausteinChoice(.sendChannelMessage, kind: ChannelEventKind.instagram),
    BausteinChoice(.notificationSend),
  ],
};

IconData _channelIcon(ChannelEventKind kind) => switch (kind) {
  ChannelEventKind.email => CupertinoIcons.mail,
  ChannelEventKind.whatsapp => SimpleIcons.whatsapp,
  ChannelEventKind.sms => CupertinoIcons.chat_bubble_text,
  ChannelEventKind.telegram => SimpleIcons.telegram,
  ChannelEventKind.instagram => SimpleIcons.instagram,
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
  .sendChannelMessage => SimpleIcons.whatsapp,
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
  .httpRequest => Icons.http,
  .readWebhook => Icons.webhook,
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
    final httpAvailable = connectionsAvailable();
    final webhookAvailable = webhooksAvailable();
    final groups = {
      for (final group in bausteinGroups.entries)
        group.key: group.value
            .where((choice) => choice.label.toLowerCase().contains(_query))
            // Ohne Verbindungs-Dienst (Cloud) gäbe es den Baustein, aber keine Ausführung.
            .where(
              (choice) =>
                  httpAvailable ||
                  choice.primitive != WorkflowPrimitive.httpRequest,
            )
            .where(
              (choice) =>
                  webhookAvailable ||
                  choice.primitive != WorkflowPrimitive.readWebhook,
            )
            .toList(),
    };
    for (final module in PluginNodeModules.all) {
      if (!module.isAvailable() ||
          !module.title.toLowerCase().contains(_query)) {
        continue;
      }
      (groups[module.group] ??= []).add(BausteinChoice.plugin(module));
    }
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
                LocaleKeys.task_builder_palette_title.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  labelText: LocaleKeys.task_builder_palette_search.tr(),
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
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(LocaleKeys.task_builder_palette_empty.tr()),
                    ),
                  for (final group in groups.entries)
                    if (group.value.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                        child: Text(
                          _upperCase(context, _groupTitle(group.key)),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      for (final choice in group.value)
                        Draggable<BausteinChoice>(
                          data: choice,
                          maxSimultaneousDrags: choice.isAvailable ? 1 : 0,
                          feedback: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(choice.label),
                            ),
                          ),
                          child: AgentCursorAnchor(
                            target: TaskBuilderCursorTargets.palette(
                              choice.primitive,
                              kind: choice.kind,
                              pluginTypeId: choice.pluginTypeId,
                            ),
                            onActivate: choice.isAvailable
                                ? () => widget.onAdd(choice)
                                : null,
                            child: ListTile(
                              enabled: choice.isAvailable,
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
                                  color: choice.isAvailable
                                      ? colors.onSurfaceVariant
                                      : colors.outline,
                                ),
                              ),
                              title: Text(
                                _displayLabel(choice),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: choice.isAvailable
                                          ? null
                                          : colors.outline,
                                    ),
                              ),
                              onTap: choice.isAvailable
                                  ? () => widget.onAdd(choice)
                                  : null,
                            ),
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

String _displayLabel(BausteinChoice choice) => choice.isAvailable
    ? choice.label
    : '${choice.label} ${LocaleKeys.task_builder_palette_coming_soon.tr()}';

/// Eingebaute Gruppen sind Übersetzungsschlüssel, Plugin-Gruppen Klartext.
String _groupTitle(String key) =>
    key.startsWith('task_builder.') ? key.tr() : key;

/// Dart-`toUpperCase` kennt kein türkisches i/İ; dort würde „iletişim“ zu „ILETIŞIM“.
String _upperCase(BuildContext context, String text) {
  final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
  final prepared = isTurkish
      ? text.replaceAll('i', 'İ').replaceAll('ı', 'I')
      : text;
  return prepared.toUpperCase();
}

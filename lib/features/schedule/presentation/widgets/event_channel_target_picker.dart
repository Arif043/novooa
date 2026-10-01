import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../communication/domain/entities/communication_channel.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../cubits/event_target_options_state.dart';
import 'event_target_tile.dart';

/// Zielwahl für Nachrichten: ein Kommunikationskanal (SMS, WhatsApp) oder ein
/// Mail-Postfach. „Überall" reagiert auf jeden passenden Eingang.
class EventChannelTargetPicker extends StatelessWidget {
  const EventChannelTargetPicker({
    super.key,
    required this.source,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final EventTriggerSource source;
  final EventTargetOptionsState options;
  final EventTriggerTarget selected;
  final ValueChanged<EventTriggerTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final channels = _matchingChannels();
    return ListView(
      children: [
        EventTargetTile(
          icon: Icons.all_inclusive,
          title: 'Überall',
          selected: selected is AnywhereTarget,
          onTap: () => onChanged(EventTriggerTarget.anywhere),
        ),
        for (final channel in channels) _channelTile(channel),
        if (channels.isEmpty) const _NoChannelsHint(),
      ],
    );
  }

  Widget _channelTile(CommunicationChannel channel) {
    final target = _targetFor(channel);
    return EventTargetTile(
      icon: _iconFor(channel.kind),
      title: channel.label,
      subtitle: channel.address,
      selected: _isSelected(target),
      onTap: () => onChanged(target),
    );
  }

  EventTriggerTarget _targetFor(CommunicationChannel channel) {
    if (source == EventTriggerSource.emailReceived) {
      return ConnectorTarget(id: channel.connectorId!, name: channel.label);
    }
    return ChannelTarget(id: channel.id, name: channel.label);
  }

  bool _isSelected(EventTriggerTarget target) {
    return switch ((selected, target)) {
      (ConnectorTarget a, ConnectorTarget b) => a.id == b.id,
      (ChannelTarget a, ChannelTarget b) => a.id == b.id,
      _ => false,
    };
  }

  List<CommunicationChannel> _matchingChannels() {
    return options.channels.where(_matchesSource).toList(growable: false);
  }

  bool _matchesSource(CommunicationChannel channel) {
    if (!channel.isActive || !channel.capabilities.inbound) return false;
    return switch (source) {
      EventTriggerSource.emailReceived =>
        channel.kind == CommunicationChannelKind.email &&
            channel.isConnectorBacked,
      EventTriggerSource.smsMessageReceived =>
        channel.kind == CommunicationChannelKind.sms,
      EventTriggerSource.whatsappMessageReceived =>
        channel.kind == CommunicationChannelKind.whatsapp,
      _ => false,
    };
  }

  IconData _iconFor(CommunicationChannelKind kind) {
    return switch (kind) {
      CommunicationChannelKind.email => Icons.mail_outline,
      CommunicationChannelKind.sms => Icons.sms_outlined,
      CommunicationChannelKind.whatsapp => Icons.chat_outlined,
    };
  }
}

class _NoChannelsHint extends StatelessWidget {
  const _NoChannelsHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Noch nichts verbunden. Unter Einstellungen › Kommunikation '
        'kannst du Kanäle und Postfächer hinzufügen.',
      ),
    );
  }
}

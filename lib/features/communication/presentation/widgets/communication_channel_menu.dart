import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

enum _ChannelAction { fakeMessage, sendMessage, delete }

/// Weitere Aktionen eines Kanals. Ohne eine einzige Aktion erscheint kein
/// Menü.
class CommunicationChannelMenu extends StatelessWidget {
  const CommunicationChannelMenu({
    super.key,
    this.onFakeMessage,
    this.onSendMessage,
    this.onDelete,
  });

  final VoidCallback? onFakeMessage;
  final VoidCallback? onSendMessage;
  final VoidCallback? onDelete;

  bool get hasActions =>
      onFakeMessage != null || onSendMessage != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    if (!hasActions) return const SizedBox.shrink();
    return PopupMenuButton<_ChannelAction>(
      tooltip: 'Kanalmenü öffnen',
      icon: const Icon(Icons.more_horiz),
      onSelected: _run,
      itemBuilder: (_) => [
        if (onFakeMessage != null)
          const PopupMenuItem(
            value: _ChannelAction.fakeMessage,
            child: _Row(icon: Icons.bolt_outlined, label: 'Testnachricht'),
          ),
        if (onSendMessage != null)
          const PopupMenuItem(
            value: _ChannelAction.sendMessage,
            child: _Row(icon: Icons.send_outlined, label: 'Nachricht senden'),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: _ChannelAction.delete,
            child: _Row(icon: Icons.delete_outline, label: 'Entfernen'),
          ),
      ],
    );
  }

  void _run(_ChannelAction action) {
    switch (action) {
      case _ChannelAction.fakeMessage:
        onFakeMessage?.call();
      case _ChannelAction.sendMessage:
        onSendMessage?.call();
      case _ChannelAction.delete:
        onDelete?.call();
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.lg),
        const SizedBox(width: AppSpacing.md),
        Text(label),
      ],
    );
  }
}

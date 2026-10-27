import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../../../core/widgets/luminous_card.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../cubits/schedule_cubit.dart';
import 'schedule_formatters.dart';
import '../../../integrations/shopware/presentation/widgets/shopware_app_dialog.dart';
import 'webhook_address.dart';

class TaskTriggerTile extends StatefulWidget {
  const TaskTriggerTile({
    super.key,
    required this.trigger,
    required this.cubit,
  });
  final TaskTrigger trigger;
  final ScheduleCubit cubit;
  @override
  State<TaskTriggerTile> createState() => _TaskTriggerTileState();
}

class _TaskTriggerTileState extends State<TaskTriggerTile> {
  bool _busy = false;

  Future<void> _perform(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Die Änderung konnte nicht gespeichert werden. Bitte versuche es erneut.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Auslöser löschen?'),
        content: Text(
          '„${widget.trigger.taskTitle}“ wird durch diesen Auslöser nicht mehr gestartet. Die Aufgabe bleibt erhalten.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform(() => widget.cubit.deleteTrigger(widget.trigger));
    }
  }

  Future<void> _copyAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Adresse kopiert.')));
  }

  Future<void> _rotateAddress() async {
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Neue Adresse erzeugen?'),
        content: const Text(
          'Die bisherige Adresse funktioniert danach nicht mehr. Trage die '
          'neue Adresse beim externen System ein.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Neue Adresse'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform(() => widget.cubit.rotateWebhookToken(widget.trigger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.trigger;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LuminousCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuminousCardHeading(
            icon: _iconFor(trigger),
            title: trigger.taskTitle,
            subtitle: triggerLabel(trigger),
          ),
          if (trigger.event?.source == EventTriggerSource.shopware &&
              trigger.webhookUrl != null) ...[
            const SizedBox(height: 16),
            _ShopwareAppPanel(trigger: trigger),
          ] else if (trigger.webhookUrl case final address?) ...[
            const SizedBox(height: 16),
            WebhookAddress(
              address: address,
              verified:
                  trigger.event?.webhook?.verification
                      is HmacWebhookVerification,
              busy: _busy,
              onCopy: () => _copyAddress(address),
              onRotate: _rotateAddress,
            ),
          ],
          const SizedBox(height: 20),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                triggerStatusLabel(trigger),
                style: theme.textTheme.bodySmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trigger.enabled ? 'Aktiv' : 'Pausiert',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Auslöser für ${trigger.taskTitle}',
                    child: CupertinoSwitch(
                      value: trigger.enabled,
                      activeTrackColor: SyscatTheme.primaryOrange,
                      onChanged: _busy
                          ? null
                          : (value) => _perform(
                              () => widget.cubit.setEnabled(trigger, value),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: CupertinoActivityIndicator(),
                    )
                  else
                    IconButton(
                      tooltip: 'Auslöser löschen',
                      onPressed: _delete,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        CupertinoIcons.trash,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(TaskTrigger trigger) {
  if (trigger.type == TriggerType.schedule) return CupertinoIcons.clock;
  return switch (trigger.event?.source) {
    EventTriggerSource.emailReceived => CupertinoIcons.envelope,
    EventTriggerSource.smsMessageReceived => CupertinoIcons.chat_bubble,
    EventTriggerSource.whatsappMessageReceived => CupertinoIcons.chat_bubble_2,
    EventTriggerSource.fileCreated => CupertinoIcons.doc,
    EventTriggerSource.fileVersionCreated => CupertinoIcons.doc_on_doc,
    EventTriggerSource.fileDeleted => CupertinoIcons.trash,
    EventTriggerSource.webhookReceived => CupertinoIcons.link,
    EventTriggerSource.shopware => CupertinoIcons.cart,
    null => CupertinoIcons.bolt,
  };
}

/// Statt der Adresse (sie steckt in der App): der Weg, die Shopware-App
/// einzurichten.
class _ShopwareAppPanel extends StatelessWidget {
  const _ShopwareAppPanel({required this.trigger});

  final TaskTrigger trigger;

  @override
  Widget build(BuildContext context) {
    final event = trigger.event;
    final address = Uri.tryParse(trigger.webhookUrl ?? '');
    if (event == null || address == null) return const SizedBox.shrink();
    // Der Pfad endet auf /hooks/<id>/<token>; davor liegt die Adresse von novooa.
    final prefix = address.pathSegments.length >= 3
        ? address.pathSegments.sublist(0, address.pathSegments.length - 3)
        : const <String>[];
    final base = address
        .replace(pathSegments: prefix, query: null, fragment: null)
        .toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shopware meldet dieses Ereignis über eine kleine App. Ohne sie '
          'startet der Auslöser nie.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton.icon(
          key: const Key('shopware-app-open'),
          onPressed: () => ShopwareAppDialog.show(
            context,
            triggerId: trigger.id,
            token: event.webhook?.token ?? '',
            params: event.shopware,
            initialAddress: base,
          ),
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: const Text('Shopware-App einrichten'),
        ),
      ],
    );
  }
}

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';

/// Warnt vor möglichen Schleifen und lässt den Nutzer bewusst entscheiden.
/// Liefert `true`, wenn der Auslöser trotzdem erstellt werden soll.
class TriggerCycleWarningDialog extends StatelessWidget {
  const TriggerCycleWarningDialog({super.key, required this.warnings});

  final List<String> warnings;

  static Future<bool> show(BuildContext context, List<String> warnings) async {
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (_) => TriggerCycleWarningDialog(warnings: warnings),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Mögliche Schleife'),
      content: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          children: [
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(warning),
              ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Zurück'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Trotzdem erstellen'),
        ),
      ],
    );
  }
}

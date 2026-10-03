import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'communication_connect_actions.dart';

/// Leerzustand mit der einen Aktion, die weiterhilft.
class CommunicationEmptyState extends StatelessWidget {
  const CommunicationEmptyState({super.key, required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.forum_outlined,
      title: 'Noch keine Verbindungen',
      message:
          'Verbinde ein Postfach, damit Aufgaben E-Mails empfangen und '
          'senden können.',
      actionLabel: connectActionLabel,
      onAction: onConnect,
    );
  }
}

/// Fehlschlag ohne Daten: Es gibt nichts anzuzeigen außer dem Neuversuch.
class CommunicationFailureState extends StatelessWidget {
  const CommunicationFailureState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.cloud_off_outlined,
      title: 'Postfächer nicht erreichbar',
      message:
          'Die Verbindungen konnten nicht geladen werden. Prüfe deine '
          'Internetverbindung und versuche es erneut.',
      actionLabel: 'Erneut versuchen',
      onAction: onRetry,
    );
  }
}

/// Fehlschlag mit Daten: Die Karten bleiben sichtbar, der Hinweis steht darüber.
class CommunicationFailureBanner extends StatelessWidget {
  const CommunicationFailureBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Nicht alle Verbindungen konnten geladen werden.'),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppSpacing.xxl,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../app/dashboard_theme.dart';
import '../l10n/dashboard_keys.dart';

/// Ladezustand mit optionalem Hinweis.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (label case final text?) ...[
          const SizedBox(height: Spacing.md),
          Text(text, textAlign: TextAlign.center),
        ],
      ],
    ),
  );
}

/// Fehlerzustand: verständliche Meldung und „Erneut versuchen“.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CenteredMessage(
    icon: Icons.cloud_off_outlined,
    message: message,
    actionLabel: DashboardKeys.retry.tr(),
    onAction: onRetry,
  );
}

/// Leerer Zustand mit einer Aktion, die weiterhilft.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _CenteredMessage(
    icon: Icons.inbox_outlined,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: Spacing.xl * 1.5,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: Spacing.md),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel case final label?) ...[
              const SizedBox(height: Spacing.md),
              FilledButton.tonal(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}

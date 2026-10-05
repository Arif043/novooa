import 'package:flutter/material.dart';

/// Die Adresse, die ein externes System aufruft, samt Hinweis zum Schutz.
class WebhookAddress extends StatelessWidget {
  const WebhookAddress({
    super.key,
    required this.address,
    required this.verified,
    required this.busy,
    required this.onCopy,
    required this.onRotate,
  });

  final String address;
  final bool verified;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onRotate;

  bool get _unencrypted => address.startsWith('http://');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Adresse für das externe System',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    address,
                    key: const Key('webhook-address'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Adresse kopieren',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined, size: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          verified
              ? 'Aufrufe werden zusätzlich über ihre Signatur geprüft.'
              : 'Ohne Signaturprüfung startet jeder Aufruf mit dieser Adresse '
                    'die Aufgabe. Behandle die Adresse wie ein Passwort.',
          style: theme.textTheme.bodySmall,
        ),
        if (_unencrypted) ...[
          const SizedBox(height: 4),
          Text(
            'Die Adresse beginnt mit http: Aufrufe sind unverschlüsselt. '
            'Für externe Systeme ist https nötig.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: busy ? null : onRotate,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Neue Adresse erzeugen'),
          ),
        ),
      ],
    );
  }
}

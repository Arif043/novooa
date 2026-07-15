import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';

class TeamIdDisplay extends StatelessWidget {
  const TeamIdDisplay({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team-ID',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(teamId),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Team-ID kopieren',
              onPressed: () => _copyTeamId(context),
              icon: const Icon(Icons.copy_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyTeamId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: teamId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Team-ID kopiert.')));
  }
}

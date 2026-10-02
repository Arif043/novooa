import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Zeigt, wo der Skills-Ordner liegt: Dort angelegte Ordner mit einer
/// `SKILL.md` sind sofort Fähigkeiten.
class SkillsFolderHint extends StatelessWidget {
  const SkillsFolderHint({
    super.key,
    required this.location,
    required this.onRescan,
  });

  final String? location;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final path = location;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skills-Ordner', style: textTheme.labelMedium),
                SelectableText(path ?? '…', style: textTheme.bodySmall),
              ],
            ),
          ),
          if (path != null) _CopyButton(path: path),
          IconButton(
            tooltip: 'Neu einlesen',
            onPressed: onRescan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Pfad kopieren',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: path));
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pfad kopiert.')));
      },
      icon: const Icon(Icons.copy_outlined),
    );
  }
}

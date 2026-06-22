import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';

/// Glas-Leiste am unteren Rand des Builders.
///
/// Aufbau: links Status („N Bausteine im Flow") + sekundäre Aktionen
/// (Vorschau, Testen), rechts Verwerfen + Speichern (Hauptaktion,
/// orange, 48 px hoch). Bewusst kein „Jetzt starten" — das Auslösen
/// von Aufgaben ist Domäne des Zeitplan-Tabs.
class BuilderFooter extends StatelessWidget {
  const BuilderFooter({
    super.key,
    required this.nodeCount,
    required this.onSave,
    required this.onDiscard,
  });

  final int nodeCount;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SyscatTheme.glassSurfaceSoft,
        border: Border(
          top: BorderSide(color: SyscatTheme.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _StatusGroup(nodeCount: nodeCount),
          const Spacer(),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: SyscatTheme.textSecondary,
            ),
            child: const Text('Verwerfen'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SaveButton(onSave: onSave),
        ],
      ),
    );
  }
}

class _StatusGroup extends StatelessWidget {
  const _StatusGroup({required this.nodeCount});

  final int nodeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.bolt_outlined,
          size: 16,
          color: SyscatTheme.primaryOrangeDark,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$nodeCount ${nodeCount == 1 ? "Baustein" : "Bausteine"} im Flow',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: AppSpacing.lg),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: SyscatTheme.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Vorschau'),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: SyscatTheme.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Testen'),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onSave,
        style: FilledButton.styleFrom(
          backgroundColor: SyscatTheme.primaryOrangeDark,
          foregroundColor: SyscatTheme.textMainLight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.save_outlined, size: 18),
        label: const Text(
          'Speichern',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
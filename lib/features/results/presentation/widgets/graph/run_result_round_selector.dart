import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Die Rundenwahl einer Schleife: gewählte Runde (ab 0), Anzahl, Wechsel.
typedef RoundChoice = ({int round, int count, ValueChanged<int> onChanged});

/// „Runde 2 von 12 ‹ ›“ in der Fußzeile einer Schleifen-Karte.
class RunResultRoundLine extends StatelessWidget {
  const RunResultRoundLine({super.key, required this.choice});

  final RoundChoice choice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            LocaleKeys.results_round_of.tr(
              namedArgs: {
                'round': '${choice.round + 1}',
                'count': '${choice.count}',
              },
            ),
            style: textTheme.labelSmall,
          ),
        ),
        _RoundButton(
          icon: Icons.chevron_left,
          tooltip: LocaleKeys.results_previous_round.tr(),
          onPressed: choice.round > 0
              ? () => choice.onChanged(choice.round - 1)
              : null,
        ),
        _RoundButton(
          icon: Icons.chevron_right,
          tooltip: LocaleKeys.results_next_round.tr(),
          onPressed: choice.round < choice.count - 1
              ? () => choice.onChanged(choice.round + 1)
              : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: AppSpacing.xl,
        height: AppSpacing.lg,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.md + AppSpacing.xs),
    );
  }
}

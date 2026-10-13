import 'package:flutter/material.dart';
import '../../../../core/theme/luminous_page_theme.dart';

/// Der Zeitplan nutzt den gemeinsamen Seitenstil.
abstract final class ScheduleTheme {
  static ThemeData from(ThemeData base) => LuminousPageTheme.from(base);
}

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ],
  );
}

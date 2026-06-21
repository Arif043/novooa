import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';

class BuilderPanel extends StatelessWidget {
  const BuilderPanel({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyscatTheme.glassSurfaceSoft,
        border: Border.all(color: SyscatTheme.borderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

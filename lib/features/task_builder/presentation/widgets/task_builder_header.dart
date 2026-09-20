import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'task_builder_theme.dart';

class TaskBuilderHeader extends StatelessWidget {
  const TaskBuilderHeader({
    super.key,
    required this.title,
    required this.onMenuPressed,
    required this.actions,
  });
  final Widget title;
  final VoidCallback onMenuPressed;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: wide ? TaskBuilderTheme.paletteWidth : 56,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Menü öffnen',
                          onPressed: onMenuPressed,
                          icon: const Icon(CupertinoIcons.sidebar_left),
                        ),
                        if (wide) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(
                                alpha: .12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_tree_outlined,
                              size: 20,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aufgabenstudio',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (wide)
                    SizedBox(
                      height: 40,
                      child: VerticalDivider(
                        width: 1,
                        color: colors.outlineVariant,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wide)
                            Text('AUFGABE', style: theme.textTheme.labelSmall),
                          title,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: actions,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

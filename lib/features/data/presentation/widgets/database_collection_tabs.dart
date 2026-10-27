import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';

/// Reiter unter dem Blatt wechseln zwischen den Sammlungen, wie Arbeitsblätter.
class DatabaseCollectionTabs extends StatelessWidget {
  const DatabaseCollectionTabs({
    super.key,
    required this.state,
    required this.enabled,
  });

  final DatabaseState state;
  final bool enabled;

  /// Lange Namen werden gekürzt; der volle Name steht im Tooltip.
  static const _maxLabelWidth = 240.0;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final collection in state.collections)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Tooltip(
              message: collection.name,
              child: ChoiceChip(
                showCheckmark: false,
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .10),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
                  child: Text(
                    collection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                avatar: const Icon(
                  CupertinoIcons.table,
                  size: AppSpacing.md + AppSpacing.xs,
                ),
                selected: collection.name == state.collection?.name,
                onSelected: enabled
                    ? (_) => context.read<DatabaseCubit>().openCollection(
                        collection,
                      )
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
}

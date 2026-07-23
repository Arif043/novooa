import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';

class KnowledgeGraphNode extends StatelessWidget {
  const KnowledgeGraphNode({
    super.key,
    required this.note,
    required this.selected,
    required this.position,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  static const double hitSize = 112;

  final KnowledgeNote note;
  final bool selected;
  final Offset position;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - hitSize / 2,
      top: position.dy - hitSize / 2,
      width: hitSize,
      height: hitSize,
      child: Semantics(
        button: true,
        label: 'Notiz ${note.title}',
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => onDragStart(),
          onPanUpdate: (details) => onDragUpdate(details.delta),
          onPanEnd: (_) => onDragEnd(),
          onPanCancel: onDragEnd,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onTap: () => context.read<KnowledgeBaseCubit>().selectNote(note.id),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NodeDot(note: note, selected: selected),
                const SizedBox(height: AppSpacing.xs),
                _NodeLabel(title: note.title, selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeDot extends StatelessWidget {
  const _NodeDot({required this.note, required this.selected});

  final KnowledgeNote note;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = 14.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: selected ? 18.0 : size,
      height: selected ? 18.0 : size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? colorScheme.primary
            : colorScheme.onInverseSurface.withValues(alpha: 0.58),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.62),
                  blurRadius: AppSpacing.lg,
                ),
              ]
            : const [],
      ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({required this.title, required this.selected});

  final String title;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: selected
            ? colorScheme.primary
            : colorScheme.onInverseSurface.withValues(alpha: 0.66),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

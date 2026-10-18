import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';

/// Wie stark eine Notiz im Graphen hervortritt: gewählt, direkt oder
/// indirekt von ihr verlinkt (im Kontext eines Prompts, der sie anhängt),
/// normal oder zurückgenommen (außerhalb dieses Kontexts).
enum KnowledgeGraphEmphasis {
  selected,
  directlyLinked,
  indirectlyLinked,
  normal,
  dimmed,
}

class KnowledgeGraphNode extends StatelessWidget {
  const KnowledgeGraphNode({
    super.key,
    required this.note,
    required this.emphasis,
    required this.degree,
    required this.position,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  static const double hitSize = 112;

  final KnowledgeNote note;
  final KnowledgeGraphEmphasis emphasis;

  /// Zahl der Links; vernetzte Notizen erscheinen größer.
  final int degree;
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
            child: AnimatedOpacity(
              opacity: emphasis == KnowledgeGraphEmphasis.dimmed ? .45 : 1,
              duration: _transitionOf(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NodeDot(emphasis: emphasis, degree: degree),
                  const SizedBox(height: AppSpacing.xs),
                  _NodeLabel(
                    title: note.title,
                    selected: emphasis == KnowledgeGraphEmphasis.selected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Duration _transitionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

class _NodeDot extends StatelessWidget {
  const _NodeDot({required this.emphasis, required this.degree});

  final KnowledgeGraphEmphasis emphasis;
  final int degree;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = 12.0 + 2 * degree.clamp(0, 5) + (_selected ? 4 : 0);
    return AnimatedContainer(
      duration: _transitionOf(context),
      curve: Curves.easeOutBack,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (emphasis) {
          KnowledgeGraphEmphasis.selected => colors.primary,
          KnowledgeGraphEmphasis.directlyLinked => Color.alphaBlend(
            colors.primary.withValues(alpha: .7),
            colors.onSurfaceVariant,
          ),
          KnowledgeGraphEmphasis.indirectlyLinked => Color.alphaBlend(
            colors.primary.withValues(alpha: .4),
            colors.onSurfaceVariant,
          ),
          _ => colors.onSurfaceVariant.withValues(alpha: .62),
        },
        boxShadow: [
          if (_glows)
            BoxShadow(
              color: colors.primary.withValues(alpha: _glowAlpha),
              blurRadius: _selected ? AppSpacing.lg : AppSpacing.md,
              spreadRadius: _selected ? 2 : 0,
            ),
        ],
      ),
    );
  }

  bool get _selected => emphasis == KnowledgeGraphEmphasis.selected;

  bool get _glows => _glowAlpha > 0;

  double get _glowAlpha => switch (emphasis) {
    KnowledgeGraphEmphasis.selected => .6,
    KnowledgeGraphEmphasis.directlyLinked => .32,
    KnowledgeGraphEmphasis.indirectlyLinked => .16,
    _ => 0,
  };
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
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

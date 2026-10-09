import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'agent_cursor_controller.dart';

/// Zeichnet den Agent-Cursor über die Oberfläche; nimmt keine Eingaben an.
class AgentCursorOverlay extends StatefulWidget {
  const AgentCursorOverlay({super.key, required this.controller});

  final AgentCursorController controller;

  @override
  State<AgentCursorOverlay> createState() => _AgentCursorOverlayState();
}

class _AgentCursorOverlayState extends State<AgentCursorOverlay> {
  final _areaKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    controller.reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox.expand(key: _areaKey),
            ?_cursor(controller),
          ],
        ),
      ),
    );
  }

  Widget? _cursor(AgentCursorController controller) {
    final global = controller.globalPosition;
    final area = _areaKey.currentContext?.findRenderObject();
    if (global == null || area is! RenderBox || !area.hasSize) return null;
    final local = area.globalToLocal(global);
    return AnimatedPositioned(
      duration: controller.reduceMotion
          ? Duration.zero
          : controller.travelDuration,
      curve: Curves.easeInOutCubic,
      left: local.dx,
      top: local.dy,
      child: _CursorMark(clickCount: controller.clickCount),
    );
  }
}

class _CursorMark extends StatelessWidget {
  const _CursorMark({required this.clickCount});

  final int clickCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'KI-Agent bedient die Oberfläche',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Ripple(key: ValueKey(clickCount), color: colors.primary),
          Icon(Icons.navigation, color: colors.primary, size: AppSpacing.lg),
          _Badge(colors: colors),
        ],
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  const _Ripple({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      builder: (context, value, _) => Transform.translate(
        offset: const Offset(-AppSpacing.md, -AppSpacing.md),
        child: Opacity(
          opacity: 1 - value,
          child: Container(
            width: AppSpacing.xl * value,
            height: AppSpacing.xl * value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        child: Text(
          'KI-Agent',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onPrimary),
        ),
      ),
    );
  }
}

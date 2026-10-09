import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'agent_cursor_controller.dart';
import 'agent_viewport_glow.dart';

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
            AgentViewportGlow(isActive: controller.isActive),
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
      label: LocaleKeys.ui_ki_agent_bedient_die_oberflaeche.tr(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Der Ring liegt außerhalb des Layouts, damit der Klick den Pfeil
          // nicht verschiebt.
          Positioned(
            left: -_Ripple.size / 2,
            top: -_Ripple.size / 2,
            child: _Ripple(key: ValueKey(clickCount), color: colors.primary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.navigation,
                color: colors.primary,
                size: AppSpacing.lg,
              ),
              _Badge(colors: colors),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  const _Ripple({super.key, required this.color});

  static const size = AppSpacing.xl;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final isFirstBuild = key == const ValueKey(0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: isFirstBuild ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: 1 - value,
        child: Transform.scale(scale: value, child: child),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
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
          LocaleKeys.ui_ki_agent.tr(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onPrimary),
        ),
      ),
    );
  }
}

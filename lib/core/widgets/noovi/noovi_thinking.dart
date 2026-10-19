import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../localization/locale_keys.g.dart';
import '../../theme/app_spacing.dart';
import 'noovi_image.dart';
import 'noovi_pose.dart';

/// Noovi denkt nach und schwebt dabei sanft auf und ab; bei reduzierten
/// Animationen steht er still.
class NooviThinking extends StatefulWidget {
  const NooviThinking({super.key, required this.size});

  final double size;

  @override
  State<NooviThinking> createState() => _NooviThinkingState();
}

class _NooviThinkingState extends State<NooviThinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: LocaleKeys.ui_noovi_thinking.tr(),
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, _offset), child: child),
        child: NooviImage(pose: NooviPose.thinking, size: widget.size),
      ),
    );
  }

  double get _offset {
    final eased = Curves.easeInOut.transform(_float.value);
    return (eased * 2 - 1) * AppSpacing.xs;
  }
}

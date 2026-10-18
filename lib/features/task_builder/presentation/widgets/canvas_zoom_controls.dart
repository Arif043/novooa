import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Zoomleiste der Leinwand: verkleinern, aktuelle Stufe, vergrößern, alles
/// einpassen.
class CanvasZoomControls extends StatelessWidget {
  const CanvasZoomControls({
    super.key,
    required this.transform,
    required this.onZoom,
    required this.onFitAll,
  });

  final TransformationController transform;
  final ValueChanged<double> onZoom;
  final VoidCallback onFitAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: LocaleKeys.task_builder_canvas_zoom_out.tr(),
            onPressed: () => onZoom(.8),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 56,
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: transform,
              builder: (_, matrix, _) => Text(
                '${(matrix.getMaxScaleOnAxis() * 100).round()} %',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            tooltip: LocaleKeys.task_builder_canvas_zoom_in.tr(),
            onPressed: () => onZoom(1.25),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: LocaleKeys.task_builder_canvas_fit_all.tr(),
            icon: const Icon(Icons.fit_screen),
            onPressed: onFitAll,
          ),
        ],
      ),
    );
  }
}

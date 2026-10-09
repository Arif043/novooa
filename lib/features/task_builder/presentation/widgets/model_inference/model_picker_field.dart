import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import '../../../domain/entities/workflow_node.dart';
import 'model_cache_status_row.dart';
import 'model_inference_selection.dart';
import 'model_search_filter.dart';
import 'model_search_sheet.dart';

/// Zeigt das gewählte Modell samt Cache-Status; Tippen öffnet die Katalogsuche.
class ModelPickerField extends StatelessWidget {
  const ModelPickerField({
    super.key,
    required this.node,
    required this.modelId,
    required this.state,
    this.speechDirection,
  });

  final WorkflowNode node;
  final String modelId;
  final ModelCatalogState state;
  final SpeechModelDirection? speechDirection;

  @override
  Widget build(BuildContext context) {
    final model = state.entryById(modelId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: LocaleKeys.ui_modell_aus_dem_katalog_auswaehlen.tr(),
          child: InkWell(
            onTap: () => _search(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: LocaleKeys.ui_modell.tr(),
                suffixIcon: Icon(Icons.search),
              ),
              child: Text(
                _labelFor(context, model),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (modelId.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ModelCacheStatusRow(modelId: modelId, state: state),
        ],
      ],
    );
  }

  String _labelFor(BuildContext context, ModelCatalogEntry? model) {
    if (modelId.isEmpty) return LocaleKeys.ui_pick_model_from_catalog.tr();
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    return model?.titleFor(languageTag) ?? modelId;
  }

  Future<void> _search(BuildContext context) async {
    final model = await showModelSearchSheet(
      context,
      speechDirection: speechDirection,
    );
    if (model == null || !context.mounted) return;
    selectInferenceModel(context, node, model);
  }
}

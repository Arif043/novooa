import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_collection.dart';
import '../cubits/database_import_cubit.dart';
import '../cubits/database_import_state.dart';
import 'database_feedback_text.dart';
import 'database_import_preview_view.dart';

/// Führt durch den Import; liefert die Anzahl übernommener Datensätze oder `null`.
Future<int?> showDatabaseImportDialog(
  BuildContext context,
  DataCollection collection,
) {
  final factory = context.read<DatabaseImportCubitFactory>();
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => factory(collection)..start(),
      child: _ImportDialog(collection: collection),
    ),
  );
}

class _ImportDialog extends StatelessWidget {
  const _ImportDialog({required this.collection});

  final DataCollection collection;

  /// Lesbare Breite für Vorschau und Meldungen, auch in breiten Fenstern.
  static const _maxWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DatabaseImportCubit, DatabaseImportState>(
      listenWhen: (before, after) => before.step != after.step,
      listener: (context, state) {
        if (state.step == DatabaseImportStep.done) {
          Navigator.of(context).pop(state.importedCount);
        } else if (state.step == DatabaseImportStep.cancelled) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) => AlertDialog(
        title: Text(
          LocaleKeys.ui_db_import_title.tr(
            namedArgs: {'name': collection.name},
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: SizedBox(width: double.maxFinite, child: _body(state)),
        ),
        actions: _actions(context, state),
      ),
    );
  }

  Widget _body(DatabaseImportState state) => switch (state.step) {
    DatabaseImportStep.preview => DatabaseImportPreviewView(
      preview: state.preview!,
      fileName: state.file?.name ?? '',
    ),
    DatabaseImportStep.failed => Text(dataFailureText(state.failure!)),
    DatabaseImportStep.importing => _Progress(
      LocaleKeys.ui_db_import_importing.tr(),
    ),
    _ => _Progress(LocaleKeys.ui_db_import_reading.tr()),
  };

  List<Widget> _actions(BuildContext context, DatabaseImportState state) {
    final cubit = context.read<DatabaseImportCubit>();
    final canChooseAgain =
        state.step == DatabaseImportStep.preview ||
        state.step == DatabaseImportStep.failed;
    return [
      TextButton(
        onPressed: state.isWorking ? null : () => Navigator.of(context).pop(),
        child: Text(LocaleKeys.ui_abbrechen.tr()),
      ),
      if (canChooseAgain)
        TextButton(
          onPressed: cubit.start,
          child: Text(LocaleKeys.ui_db_import_other_file.tr()),
        ),
      if (state.step == DatabaseImportStep.preview)
        FilledButton(
          onPressed: state.preview!.canImport ? cubit.confirm : null,
          child: Text(
            LocaleKeys.ui_db_import_confirm.tr(
              namedArgs: {'count': '${state.preview!.count}'},
            ),
          ),
        ),
    ];
  }
}

class _Progress extends StatelessWidget {
  const _Progress(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CupertinoActivityIndicator(),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label)),
      ],
    );
  }
}

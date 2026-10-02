import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';

import '../cubits/skill_catalog_cubit.dart';
import '../cubits/skill_import_cubit.dart';
import '../cubits/skill_import_state.dart';
import 'skill_import_review.dart';
import 'skill_import_source_picker.dart';

/// Import in einem Sheet (Bottom Sheet mobil, Fenster-Sheet auf dem Desktop):
/// Quelle wählen → gefundene Skills prüfen → übernehmen.
class SkillImportSheet extends StatelessWidget {
  const SkillImportSheet({super.key, required this.style});

  final AdaptiveSheetStyle style;

  static Future<void> show(BuildContext context) {
    return showAdaptiveSheet<void>(
      context: context,
      builder: (_, style) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => serviceLocator<SkillImportCubit>()),
          BlocProvider(
            create: (_) => serviceLocator<SkillCatalogCubit>()..load(),
          ),
        ],
        child: SkillImportSheet(style: style),
      ),
    );
  }

  static const _windowSheetHeight = 560.0;

  @override
  Widget build(BuildContext context) {
    final isWindow = style.isWindow;
    return SizedBox(
      height: isWindow
          ? _windowSheetHeight
          : MediaQuery.sizeOf(context).height * 0.85,
      child: BlocBuilder<SkillImportCubit, SkillImportState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Fähigkeiten importieren',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (state.message != null) _Message(text: state.message!),
            Expanded(child: _Step(state: state)),
            _Actions(state: state, isWindow: isWindow),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.state});

  final SkillImportState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.step) {
      SkillImportStep.chooseSource => const SkillImportSourcePicker(),
      SkillImportStep.loading => const _Busy(text: 'Quelle wird gelesen …'),
      SkillImportStep.saving => const _Busy(
        text: 'Skills werden gespeichert …',
      ),
      SkillImportStep.review => SkillImportReview(state: state),
      SkillImportStep.done => _Done(count: state.importedCount),
    };
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(text),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: AppSpacing.xl),
          const SizedBox(height: AppSpacing.md),
          Text(
            count == 1
                ? '1 Fähigkeit importiert.'
                : '$count Fähigkeiten importiert.',
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(text, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.isWindow});

  final SkillImportState state;
  final bool isWindow;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SkillImportCubit>();
    final done = state.step == SkillImportStep.done;
    final confirm = switch (state.step) {
      SkillImportStep.review when state.canCommit => cubit.commit,
      SkillImportStep.done => () => Navigator.of(context).pop(),
      _ => null,
    };
    final label = done ? 'Fertig' : '${state.selected.length} importieren';
    void close() => Navigator.of(context).pop();
    if (isWindow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          SheetFooter(
            onCancel: close,
            confirmLabel: state.step == SkillImportStep.review || done
                ? label
                : null,
            onConfirm: confirm,
          ),
        ],
      );
    }
    if (state.step != SkillImportStep.review && !done) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FilledButton(onPressed: confirm, child: Text(label)),
    );
  }
}

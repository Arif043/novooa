import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/layout/page_insets.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/luminous_page_theme.dart';
import 'package:syscat2/core/widgets/luminous_page_header.dart';

import '../cubits/skills_cubit.dart';
import '../cubits/skills_state.dart';
import '../widgets/skill_card.dart';
import '../widgets/skill_import_sheet.dart';
import '../widgets/skills_empty_state.dart';
import '../widgets/skills_status_placeholder.dart';

/// Übersicht der Fähigkeiten (Skills). Das Skills-Verzeichnis der Anwendung ist
/// die Quelle der Wahrheit: Die Seite zeigt, was darin liegt, und bietet den
/// Import (GitHub, ZIP, Ordner, Katalog) an. Layout wie der Zeitplan.
class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<SkillsCubit>()..load(),
      child: const SkillsView(),
    );
  }
}

/// Seite ohne eigenen Cubit — erwartet [SkillsCubit] im Kontext (für Tests und Einbettung).
class SkillsView extends StatelessWidget {
  const SkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LuminousPageTheme.from(Theme.of(context)),
      child: Builder(
        builder: (context) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: SafeArea(
            child: BlocConsumer<SkillsCubit, SkillsState>(
              listenWhen: (previous, current) =>
                  current.message != null &&
                  previous.message != current.message,
              listener: _showMessage,
              builder: (context, state) => _SkillsBody(state: state),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, SkillsState state) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(state.message!)));
    context.read<SkillsCubit>().messageShown();
  }
}

class _SkillsBody extends StatelessWidget {
  const _SkillsBody({required this.state});

  final SkillsState state;

  bool get _hasSkills =>
      state.status == SkillsStatus.ready && state.skills.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (state.status == SkillsStatus.ready && state.skills.isEmpty) {
      return SkillsEmptyState(onImport: () => SkillImportSheet.show(context));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = PageInsets.forWidth(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                insets.inset,
                AppSpacing.xl,
                insets.inset,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(child: _Header(state: state)),
            ),
            if (_hasSkills) _list(insets) else _placeholder(context, insets),
          ],
        );
      },
    );
  }

  Widget _list(PageInsets insets) => SliverPadding(
    padding: EdgeInsets.fromLTRB(
      insets.inset,
      0,
      insets.inset,
      AppSpacing.pageDesktop,
    ),
    sliver: SliverList.separated(
      itemCount: state.skills.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
      itemBuilder: (_, index) => SkillCard(
        key: ValueKey(state.skills[index].name),
        skill: state.skills[index],
      ),
    ),
  );

  Widget _placeholder(BuildContext context, PageInsets insets) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.all(insets.gutter),
          child: SkillsStatusPlaceholder(
            loading: state.status == SkillsStatus.loading,
            message: state.message,
            onRetry: context.read<SkillsCubit>().load,
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final SkillsState state;

  @override
  Widget build(BuildContext context) {
    final count = state.skills.length;
    return LuminousPageHeader(
      title: LocaleKeys.ui_faehigkeiten.tr(),
      subtitle: LocaleKeys.ui_skills_page_subtitle.tr(),
      summary: state.status == SkillsStatus.ready && count > 0
          ? (count == 1
                ? LocaleKeys.ui_skills_count_one.tr()
                : LocaleKeys.ui_skills_count_other.tr(
                    namedArgs: {'count': '$count'},
                  ))
          : null,
      action: FilledButton.icon(
        onPressed: () => SkillImportSheet.show(context),
        icon: const Icon(
          CupertinoIcons.arrow_down_to_line,
          size: AppSpacing.gutter,
        ),
        label: Text(LocaleKeys.ui_skills_import.tr()),
      ),
    );
  }
}

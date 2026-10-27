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
import 'package:syscat2/core/widgets/luminous_status_placeholder.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';

import '../../domain/entities/employee.dart';
import '../cubits/employees_cubit.dart';
import '../cubits/employees_state.dart';
import '../widgets/employee_card.dart';
import '../widgets/employee_editor_sheet.dart';
import '../widgets/employees_empty_state.dart';

/// Verwaltung der Mitarbeiter (Subagenten): Rahmenbedingung plus Fähigkeiten. Layout wie der
/// Zeitplan.
class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<EmployeesCubit>()..load()),
        BlocProvider(
          create: (_) => serviceLocator<NodeSkillAttachmentsCubit>()..load(),
        ),
      ],
      child: const EmployeesView(),
    );
  }
}

/// Seite ohne eigene Cubits — erwartet [EmployeesCubit] und [NodeSkillAttachmentsCubit] im
/// Kontext (für Tests und Einbettung).
class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LuminousPageTheme.from(Theme.of(context)),
      child: Builder(
        builder: (context) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: SafeArea(
            child: BlocConsumer<EmployeesCubit, EmployeesState>(
              listenWhen: (previous, current) =>
                  current.message != null &&
                  previous.message != current.message,
              listener: _showMessage,
              builder: (context, state) => _EmployeesBody(state: state),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, EmployeesState state) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(state.message!)));
    context.read<EmployeesCubit>().messageShown();
  }
}

/// Öffnet den Editor für einen neuen ([employee] null) oder bestehenden Mitarbeiter.
Future<void> _edit(BuildContext context, [Employee? employee]) {
  final employees = context.read<EmployeesCubit>();
  final skills = context.read<NodeSkillAttachmentsCubit>();
  return EmployeeEditorSheet.show(
    context,
    initial: employee,
    onSave: (draft) => employees.save(draft, employeeId: employee?.id),
    provide: (child) => BlocProvider.value(value: skills, child: child),
  );
}

class _EmployeesBody extends StatelessWidget {
  const _EmployeesBody({required this.state});

  final EmployeesState state;

  bool get _hasEmployees =>
      state.status == EmployeesStatus.ready && state.employees.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (state.status == EmployeesStatus.ready && state.employees.isEmpty) {
      return EmployeesEmptyState(onCreate: () => _edit(context));
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
            if (_hasEmployees)
              _list(context, insets)
            else
              _placeholder(context, insets),
          ],
        );
      },
    );
  }

  Widget _list(BuildContext context, PageInsets insets) => SliverPadding(
    padding: EdgeInsets.fromLTRB(
      insets.inset,
      0,
      insets.inset,
      AppSpacing.pageDesktop,
    ),
    sliver: SliverList.separated(
      itemCount: state.employees.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
      itemBuilder: (context, index) {
        final employee = state.employees[index];
        return EmployeeCard(
          key: ValueKey(employee.id),
          employee: employee,
          onEdit: () => _edit(context, employee),
          onDelete: () => context.read<EmployeesCubit>().delete(employee.id),
        );
      },
    ),
  );

  Widget _placeholder(BuildContext context, PageInsets insets) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.all(insets.gutter),
          child: LuminousStatusPlaceholder(
            loading: state.status == EmployeesStatus.loading,
            message: state.message,
            fallbackMessage: LocaleKeys.ui_employees_load_failed.tr(),
            onRetry: context.read<EmployeesCubit>().load,
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final EmployeesState state;

  @override
  Widget build(BuildContext context) {
    final count = state.employees.length;
    return LuminousPageHeader(
      title: LocaleKeys.ui_employees_page_title.tr(),
      subtitle: LocaleKeys.ui_employees_page_subtitle.tr(),
      summary: state.status == EmployeesStatus.ready && count > 0
          ? (count == 1
                ? LocaleKeys.ui_employees_count_one.tr()
                : LocaleKeys.ui_employees_count_other.tr(
                    namedArgs: {'count': '$count'},
                  ))
          : null,
      action: FilledButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(CupertinoIcons.add, size: AppSpacing.gutter),
        label: Text(LocaleKeys.ui_employees_create.tr()),
      ),
    );
  }
}

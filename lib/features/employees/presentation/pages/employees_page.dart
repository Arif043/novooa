import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import '../cubits/employees_cubit.dart';
import '../cubits/employees_state.dart';
import '../widgets/employee_editor_dialog.dart';

/// Verwaltungsseite für Mitarbeiter (Subagents). Bietet Erstellen, Bearbeiten
/// und Löschen. Nutzt die Skill-Auswahl aus dem NodeSkillAttachmentsCubit,
/// damit die Default-Skills eines Mitarbeiters aus den vorhandenen Team-
/// Skills gewählt werden können.
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
      child: const _EmployeesView(),
    );
  }
}

class _EmployeesView extends StatelessWidget {
  const _EmployeesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeesCubit, EmployeesState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onCreate: () => _createEmployee(context)),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _Body(state: state)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createEmployee(BuildContext context) async {
    final cubit = context.read<EmployeesCubit>();
    final skillCubit = context.read<NodeSkillAttachmentsCubit>();
    final draft = await showIosDialog<EmployeeDraft>(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [BlocProvider.value(value: skillCubit)],
        child: const EmployeeEditorDialog(),
      ),
    );
    if (draft == null) return;
    await cubit.createEmployee(draft);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Mitarbeiter', style: SyscatTheme.taskBody)),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Mitarbeiter anlegen'),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final EmployeesState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      EmployeesStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      EmployeesStatus.failure => _Failure(message: state.message),
      EmployeesStatus.ready when state.employees.isEmpty => const _EmptyState(),
      EmployeesStatus.ready => _EmployeeList(employees: state.employees),
    };
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees});

  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final employee = employees[index];
        return _EmployeeTile(employee: employee);
      },
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final skillCount = employee.defaultSkills.length;
    return Container(
      decoration: SyscatTheme.nodePanelDecoration,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.person_outline),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: SyscatTheme.taskBody),
                if (employee.role.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    employee.role,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SyscatTheme.taskBodySmall,
                  ),
                ],
                if (skillCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    skillCount == 1
                        ? '1 Standard-Fähigkeit'
                        : '$skillCount Standard-Fähigkeiten',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Löschen',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<EmployeesCubit>();
    final skillCubit = context.read<NodeSkillAttachmentsCubit>();
    final draft = await showIosDialog<EmployeeDraft>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [BlocProvider.value(value: skillCubit)],
        child: EmployeeEditorDialog(initial: employee),
      ),
    );
    if (draft == null) return;
    await cubit.updateEmployee(employeeId: employee.id, draft: draft);
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<EmployeesCubit>();
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Mitarbeiter löschen?'),
        content: Text('„${employee.name}" wird endgültig entfernt.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.deleteEmployee(employee.id);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Lege deinen ersten Mitarbeiter an, um Aufgaben delegieren zu können.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? 'Mitarbeiter konnten nicht geladen werden.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => context.read<EmployeesCubit>().load(),
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

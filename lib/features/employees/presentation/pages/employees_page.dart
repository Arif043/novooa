import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';

import '../../domain/entities/employee.dart';
import '../cubits/employees_cubit.dart';
import '../cubits/employees_state.dart';
import '../widgets/employee_editor_sheet.dart';
import '../widgets/employee_list_tile.dart';

/// Verwaltung der Mitarbeiter (Subagenten): Rahmenbedingung plus Fähigkeiten.
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
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message!)));
        context.read<EmployeesCubit>().messageShown();
      },
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onCreate: () => _edit(context)),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _Body(state: state, onEdit: (e) => _edit(context, e)),
            ),
          ],
        ),
      ),
    );
  }

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
  const _Body({required this.state, required this.onEdit});

  final EmployeesState state;
  final ValueChanged<Employee> onEdit;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      EmployeesStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      EmployeesStatus.failure => _Failure(message: state.message),
      EmployeesStatus.ready when state.employees.isEmpty => const _Empty(),
      EmployeesStatus.ready => ListView.separated(
        itemCount: state.employees.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final employee = state.employees[index];
          return EmployeeListTile(
            employee: employee,
            onEdit: () => onEdit(employee),
            onDelete: () => context.read<EmployeesCubit>().delete(employee.id),
          );
        },
      ),
    };
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Noch keine Mitarbeiter. Lege einen an und weise ihn einem '
        'Prompt-Baustein zu: Seine Rahmenbedingung wird zum System-Prompt, '
        'seine Fähigkeiten bekommt der Baustein automatisch.',
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
            onPressed: context.read<EmployeesCubit>().load,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

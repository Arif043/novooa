import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../cubits/schedule_cubit.dart';
import '../cubits/schedule_state.dart';
import '../widgets/create_schedule_trigger_dialog.dart';
import '../widgets/schedule_empty_state.dart';
import '../widgets/task_trigger_list.dart';
import '../widgets/schedule_theme.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<ScheduleCubit>()..load(),
    child: const ScheduleView(),
  );
}

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});
  @override
  Widget build(BuildContext context) => Theme(
    data: ScheduleTheme.from(Theme.of(context)),
    child: Builder(
      builder: (context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: SafeArea(
          child: BlocBuilder<ScheduleCubit, ScheduleState>(
            builder: (context, state) => _isEmpty(state)
                ? ScheduleEmptyState(
                    hasTasks: state.tasks.isNotEmpty,
                    onCreateTrigger: () => _create(context),
                    onCreateTask: () => context.go(AppRouter.home),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final gutter = constraints.maxWidth < 600 ? 20.0 : 40.0;
                      final inset = constraints.maxWidth > 1080
                          ? (constraints.maxWidth - 1000) / 2
                          : gutter;
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(inset, 32, inset, 24),
                            sliver: SliverToBoxAdapter(
                              child: _ScheduleHeader(state: state),
                            ),
                          ),
                          if (state.status == ScheduleStatus.ready &&
                              state.triggers.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(inset, 0, inset, 40),
                              sliver: TaskTriggerList(
                                triggers: state.triggers,
                                cubit: context.read<ScheduleCubit>(),
                              ),
                            )
                          else
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.all(gutter),
                                child: _SchedulePlaceholder(state: state),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    ),
  );
}

bool _isEmpty(ScheduleState state) =>
    state.status == ScheduleStatus.ready && state.triggers.isEmpty;

void _create(BuildContext context) {
  final cubit = context.read<ScheduleCubit>();
  showIosDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        CreateScheduleTriggerDialog(tasks: cubit.state.tasks, cubit: cubit),
  );
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.state});
  final ScheduleState state;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.triggers.where((t) => t.enabled).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              Text('Zeitplan', style: theme.textTheme.headlineLarge),
              FilledButton.icon(
                onPressed:
                    state.status == ScheduleStatus.ready &&
                        state.tasks.isNotEmpty
                    ? () => _create(context)
                    : null,
                icon: const Icon(CupertinoIcons.add, size: 20),
                label: const Text('Auslöser hinzufügen'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Deine Aufgaben. Zur richtigen Zeit.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.status == ScheduleStatus.ready &&
            state.triggers.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '$active aktiv · ${state.triggers.length - active} pausiert',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _SchedulePlaceholder extends StatelessWidget {
  const _SchedulePlaceholder({required this.state});
  final ScheduleState state;
  @override
  Widget build(BuildContext context) {
    if (state.status == ScheduleStatus.loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final failed = state.status == ScheduleStatus.failure;
    final noTasks = state.tasks.isEmpty;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                failed
                    ? CupertinoIcons.exclamationmark_circle
                    : CupertinoIcons.calendar_badge_plus,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              failed
                  ? 'Zeitplan nicht verfügbar'
                  : noTasks
                  ? 'Alles beginnt mit einer Aufgabe'
                  : 'Platz für deine nächste Routine',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              failed
                  ? state.message ?? 'Zeitpläne konnten nicht geladen werden.'
                  : noTasks
                  ? 'Erstelle zuerst eine Aufgabe. Hier legst du anschließend fest, wann sie automatisch startet.'
                  : 'Starte Aufgaben zu einer festen Zeit oder sobald ein Ereignis eintritt.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (failed) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: context.read<ScheduleCubit>().load,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

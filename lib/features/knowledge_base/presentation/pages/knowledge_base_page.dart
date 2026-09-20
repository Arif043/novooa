import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';
import '../widgets/knowledge_base_empty_state.dart';
import '../widgets/knowledge_base_main_panel.dart';
import '../widgets/knowledge_base_shell_controller.dart';
import '../widgets/knowledge_base_sidebar.dart';
import '../widgets/knowledge_base_theme.dart';

class KnowledgeBasePage extends StatelessWidget {
  const KnowledgeBasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<KnowledgeBaseCubit>()..load(),
      child: const KnowledgeBaseShellController(child: KnowledgeBaseView()),
    );
  }
}

class KnowledgeBaseView extends StatelessWidget {
  const KnowledgeBaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KnowledgeBaseTheme.from(Theme.of(context)),
      child: BlocConsumer<KnowledgeBaseCubit, KnowledgeBaseState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: _showMessage,
        builder: (context, state) => _KnowledgeBaseBody(state: state),
      ),
    );
  }

  void _showMessage(BuildContext context, KnowledgeBaseState state) {
    final message = state.message;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _KnowledgeBaseBody extends StatelessWidget {
  const _KnowledgeBaseBody({required this.state});

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 760 ? 16 : 24,
        ),
        child: switch (state.status) {
          KnowledgeBaseStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          KnowledgeBaseStatus.failure when state.notes.isEmpty =>
            _KnowledgeBaseError(message: state.message),
          _ => _KnowledgeBaseWorkspace(state: state),
        },
      ),
    );
  }
}

class _KnowledgeBaseWorkspace extends StatelessWidget {
  const _KnowledgeBaseWorkspace({required this.state});

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    if (state.notes.isEmpty) return const KnowledgeBaseEmptyState();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900 ||
            MediaQuery.textScalerOf(context).scale(14) > 21) {
          return _MobileWorkspace(state: state);
        }
        return _DesktopWorkspace(state: state);
      },
    );
  }
}

class _DesktopWorkspace extends StatelessWidget {
  const _DesktopWorkspace({required this.state});

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 300, child: KnowledgeBaseSidebar(state: state)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: KnowledgeBaseMainPanel(state: state)),
      ],
    );
  }
}

class _MobileWorkspace extends StatefulWidget {
  const _MobileWorkspace({required this.state});

  final KnowledgeBaseState state;

  @override
  State<_MobileWorkspace> createState() => _MobileWorkspaceState();
}

class _MobileWorkspaceState extends State<_MobileWorkspace> {
  bool _showNote = false;
  @override
  Widget build(BuildContext context) => _showNote
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showNote = false),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                label: const Text('Alle Notizen'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: KnowledgeBaseMainPanel(state: widget.state)),
          ],
        )
      : KnowledgeBaseSidebar(
          state: widget.state,
          onNoteOpened: () => setState(() => _showNote = true),
        );
}

class _KnowledgeBaseError extends StatelessWidget {
  const _KnowledgeBaseError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Wissensbasis konnte nicht geladen werden.'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: context.read<KnowledgeBaseCubit>().load,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

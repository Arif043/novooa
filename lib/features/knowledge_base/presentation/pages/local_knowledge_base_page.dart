import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';
import '../widgets/knowledge_base_empty_state.dart';
import '../widgets/knowledge_base_main_panel.dart';
import '../widgets/knowledge_base_sidebar.dart';

class LocalKnowledgeBasePage extends StatelessWidget {
  const LocalKnowledgeBasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<KnowledgeBaseCubit>()..load(),
      child: const _LocalKnowledgeBaseView(),
    );
  }
}

class _LocalKnowledgeBaseView extends StatelessWidget {
  const _LocalKnowledgeBaseView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KnowledgeBaseCubit, KnowledgeBaseState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (_, state) => _LocalKnowledgeBaseBody(state: state),
    );
  }
}

class _LocalKnowledgeBaseBody extends StatelessWidget {
  const _LocalKnowledgeBaseBody({required this.state});

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: switch (state.status) {
        KnowledgeBaseStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        KnowledgeBaseStatus.failure when state.notes.isEmpty => _Failure(
          message: state.message,
        ),
        _ when state.notes.isEmpty => const KnowledgeBaseEmptyState(),
        _ => LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) return _mobileLayout();
            return _desktopLayout();
          },
        ),
      },
    );
  }

  Widget _desktopLayout() => Row(
    children: [
      SizedBox(width: 280, child: KnowledgeBaseSidebar(state: state)),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: KnowledgeBaseMainPanel(state: state)),
    ],
  );

  Widget _mobileLayout() => ListView(
    children: [
      SizedBox(height: 340, child: KnowledgeBaseSidebar(state: state)),
      const SizedBox(height: AppSpacing.md),
      SizedBox(height: 560, child: KnowledgeBaseMainPanel(state: state)),
    ],
  );
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

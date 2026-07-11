import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../cubits/knowledge_base_cubit.dart';

class KnowledgeBaseEmptyState extends StatelessWidget {
  const KnowledgeBaseEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: SyscatTheme.glassPanelDecoration,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.library_books_outlined, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Noch keine Notizen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lege deine erste Markdown-Notiz an.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: context.read<KnowledgeBaseCubit>().createNote,
                icon: const Icon(Icons.add),
                label: const Text('Notiz erstellen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

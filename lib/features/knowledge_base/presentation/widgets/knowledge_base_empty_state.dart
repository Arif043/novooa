import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/knowledge_base_cubit.dart';

class KnowledgeBaseEmptyState extends StatelessWidget {
  const KnowledgeBaseEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.book,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ein Zuhause für dein Wissen',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sammle Ideen, verknüpfe Notizen und stelle deinen Aufgaben das passende Wissen bereit.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: context.read<KnowledgeBaseCubit>().createNote,
                  icon: const Icon(CupertinoIcons.add),
                  label: const Text('Erste Notiz erstellen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Ladezustand und Fehlerzustand teilen sich dieselbe Hülle: Symbol oder
/// Fortschritt, Text und optionale Schaltflächen.
class DocumentScanMessageView extends StatelessWidget {
  const DocumentScanMessageView({
    super.key,
    required this.message,
    this.isLoading = false,
    this.actions = const [],
  });

  final String message;
  final bool isLoading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.error_outline,
                  size: AppSpacing.xxl,
                  color: scheme.error,
                ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(message, textAlign: TextAlign.center),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class TaskRunSubmittingIndicator extends StatelessWidget {
  const TaskRunSubmittingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: AppSpacing.md,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

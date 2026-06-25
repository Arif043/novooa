import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';

class TaskBuilderPage extends StatelessWidget {
  const TaskBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Toolbar(),
      SizedBox(height: AppSpacing.xxl),
     PromptWidget()
     ]);
  }
}
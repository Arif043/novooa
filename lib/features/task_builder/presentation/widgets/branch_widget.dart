
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/conditional_controller_cubit.dart';

class BranchWidget extends StatelessWidget {
  final ConditionalBranch branch;

  const BranchWidget({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            CupertinoNavigationBarBackButton(onPressed: () {
              context.read<ConditionalControllerCubit>().selectBranch(null);
            },),
            Text('Fall:  ', style: SyscatTheme.taskBody),
            // const SizedBox(width: AppSpacing.md),
            Text(branch.label, style: SyscatTheme.taskBody.copyWith(fontWeight: .w800)),
          ],
        ),
        
      ]),
    );
  }
}

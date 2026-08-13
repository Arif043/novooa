import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

final class RenameTaskAgentCommand extends TaskBuilderAgentCommand {
  const RenameTaskAgentCommand({required String label, required this.title})
    : super(label);

  final String title;

  @override
  Future<void> perform(TaskBuilderCubit cubit) => cubit.updateTitle(title);
}

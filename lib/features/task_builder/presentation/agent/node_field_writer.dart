import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

/// Schreibt ein einzelnes Feld über die Mutationen des Cubits.
class NodeFieldWriter {
  const NodeFieldWriter(this._cubit);

  final TaskBuilderCubit _cubit;

  Future<void> write(NodeId nodeId, NodeFieldKey key, String text) {
    return switch (key) {
      NodeFieldKey.title => _cubit.updateNodeTitle(nodeId, text),
      NodeFieldKey.description => _cubit.updateNodeDescription(nodeId, text),
      // Im Agenten-Protokoll heißt der Name des Hauptwerts `outputName`.
      NodeFieldKey.outputName => _cubit.renameOutput(
        nodeId: nodeId,
        key: WorkflowOutput.primaryOutputKey,
        name: text,
      ),
      NodeFieldKey.value => _cubit.updateStringInputValue(nodeId, text),
      NodeFieldKey.instruction => _cubit.updatePromptInstruction(nodeId, text),
      NodeFieldKey.modelId => _cubit.updateModelInference(nodeId, text),
      NodeFieldKey.recipient => _cubit.updateSendMessageRecipient(nodeId, text),
      NodeFieldKey.message => _cubit.updateSendMessageBody(nodeId, text),
      NodeFieldKey.script => _cubit.updateScript(nodeId, text),
      NodeFieldKey.inputTemplate => _cubit.updateScriptInput(nodeId, text),
    };
  }
}

import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

/// Ordnet plan-lokale Referenzen den IDs zu, die erst beim Ausführen entstehen.
class AgentNodeRefs {
  final _ids = <String, NodeId>{};

  void bind(String? ref, NodeId id) {
    if (ref != null) _ids[ref] = id;
  }

  NodeId resolve(String ref) => _ids[ref] ?? NodeId(ref);
}

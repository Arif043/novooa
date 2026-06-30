import 'package:flutter/material.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

class BranchWidget extends StatelessWidget {

  final ConditionalBranch branch;

  const BranchWidget({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(branch.label),
        // TODO: add nodes
        for (final nodeId in branch.nodeIds) Text(nodeId.value),
      ],
    );
  }
}
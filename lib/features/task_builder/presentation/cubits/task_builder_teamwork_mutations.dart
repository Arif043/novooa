part of 'task_builder_cubit.dart';

extension TaskBuilderTeamworkMutations on TaskBuilderCubit {
  Future<void> updateTeamworkInstruction(NodeId nodeId, String instruction) {
    return _updateTeamworkConfig(
      nodeId,
      (config) => config.copyWith(instruction: instruction),
    );
  }

  /// Modell des Orchestrators; leer = Standardmodell.
  Future<void> updateTeamworkLanguageModel(
    NodeId nodeId,
    String languageModelId,
  ) {
    return _updateTeamworkConfig(
      nodeId,
      (config) => config.copyWith(languageModelId: languageModelId),
    );
  }

  /// Schon im Team oder Team voll: keine Änderung.
  Future<void> addTeamMember(NodeId nodeId, String employeeId) {
    return _updateTeamworkConfig(
      nodeId,
      (config) => config.addMember(employeeId),
    );
  }

  Future<void> updateTeamMember(NodeId nodeId, TeamMember member) {
    return _updateTeamworkConfig(
      nodeId,
      (config) => config.updateMember(member),
    );
  }

  Future<void> removeTeamMember(NodeId nodeId, String employeeId) {
    return _updateTeamworkConfig(
      nodeId,
      (config) => config.removeMember(employeeId),
    );
  }

  /// Wie beim Prompt-Baustein: Feldnamen sind innerhalb des Bausteins eindeutig.
  Future<void> updateTeamworkOutputField({
    required NodeId nodeId,
    required int fieldIndex,
    required StructuredOutputField field,
  }) {
    return _updateTeamworkConfig(nodeId, (config) {
      final siblings = [
        for (final (index, other) in config.outputFields.indexed)
          if (index != fieldIndex) other.name,
      ];
      final uniqueField = field.copyWith(
        name: _uniqueFieldName(siblings, _normalizedOutputName(field.name)),
      );
      return config.updateOutputField(fieldIndex, uniqueField);
    });
  }

  Future<void> addTeamworkOutputField(NodeId nodeId) {
    return _updateTeamworkConfig(nodeId, (config) => config.addOutputField());
  }

  Future<void> removeTeamworkOutputField({
    required NodeId nodeId,
    required int fieldIndex,
  }) {
    return _updateTeamworkConfig(
      nodeId,
      (config) => config.removeOutputField(fieldIndex),
    );
  }

  Future<void> _updateTeamworkConfig(
    NodeId nodeId,
    TeamworkNodeConfig Function(TeamworkNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case TeamworkNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}

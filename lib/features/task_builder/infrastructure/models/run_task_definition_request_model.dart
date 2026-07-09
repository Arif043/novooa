class RunTaskDefinitionRequestModel {
  const RunTaskDefinitionRequestModel({
    required this.taskId,
    required this.context,
  });

  final String taskId;
  final String context;

  Map<String, Object?> toJson() {
    return {'taskId': taskId, 'context': context};
  }
}

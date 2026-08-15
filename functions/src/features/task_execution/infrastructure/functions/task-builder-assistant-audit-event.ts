import {logInfo} from "../../../../shared/logging/logger.js";
import {type TaskBuilderAssistantCommand} from "../../domain/entities/task-builder-assistant-response.js";

export function logTaskBuilderAssistantProposal(input: {
  uid: string;
  historyLength: number;
  commands: readonly TaskBuilderAssistantCommand[];
}): void {
  logInfo("task_builder_assistant.proposal", {
    uid: input.uid,
    historyLength: input.historyLength,
    commands: input.commands.map(commandSummary),
  });
}

function commandSummary(command: TaskBuilderAssistantCommand) {
  return {
    type: command.type,
    label: command.label,
    primitive: command.primitive,
    kind: command.kind,
  };
}

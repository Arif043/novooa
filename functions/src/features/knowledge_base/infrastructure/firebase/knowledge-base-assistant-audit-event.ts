import {logInfo} from "../../../../shared/logging/logger.js";

export type KnowledgeBaseAssistantCommandAudit = {
  type: string;
  label: string;
  title?: string;
  noteId?: string;
};

export function logKnowledgeBaseAssistantProposal(input: {
  uid: string;
  historyLength: number;
  commands: KnowledgeBaseAssistantCommandAudit[];
}): void {
  if (input.commands.length === 0) return;
  logInfo("knowledge_base_assistant.commands_proposed", {
    uid: input.uid,
    historyLength: input.historyLength,
    commandCount: input.commands.length,
    commands: input.commands.map(commandSummary),
  });
}

function commandSummary(command: KnowledgeBaseAssistantCommandAudit) {
  return {
    type: command.type,
    label: command.label,
    title: command.title,
    noteId: command.noteId,
  };
}

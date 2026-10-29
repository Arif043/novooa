import {type KnowledgeBaseAssistantNoteStore} from "../../domain/repositories/knowledge-base-assistant-note-store.js";
import {type TeamContextStore} from "../../../teams/domain/repositories/team-context-store.js";
import {assistantActorIdFromContext} from "../../../assistant/infrastructure/genkit/assistant-genkit-context.js";

export type KnowledgeNoteToolDependencies = {
  noteStore: KnowledgeBaseAssistantNoteStore;
  teamContextStore: TeamContextStore;
};

/** Das Team kommt aus der Sitzung, nie aus der Modellausgabe. */
export async function teamIdForContext(
  context: unknown,
  teamContextStore: TeamContextStore,
): Promise<string> {
  return teamContextStore.currentTeamIdForUid(assistantActorIdFromContext(context));
}

export function limitedContent(content: string, limit: number): string {
  if (content.length <= limit) return content;
  return `${content.slice(0, limit)}\n\n[Inhalt gekürzt]`;
}

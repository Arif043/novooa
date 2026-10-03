import {type RuntimeExecutor} from "../../../../db/database.js";
import {type AssistantModelSettings} from "../../../language_models/domain/repositories/assistant-model-settings.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";
import {SQLiteTeamContextStore} from "../../../teams/infrastructure/local/sqlite-team-context-store.js";
import {type KnowledgeBaseAssistant} from "../../domain/usecases/knowledge-base-assistant.js";
import {createKnowledgeBaseAssistantResponder} from "../genkit/knowledge-base-assistant-responder.js";
import {createKnowledgeBaseAssistant} from "../genkit/knowledge-base-assistant.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";
import {SQLiteKnowledgeBaseAssistantNoteStore} from "./sqlite-knowledge-base-assistant-note-store.js";

/**
 * Alle drei Tool-Abhängigkeiten existieren bereits lokal:
 * `SQLiteKnowledgeBaseAssistantNoteStore` liest dieselbe `knowledge_notes`-
 * Tabelle wie `knowledgeNoteRoutes`, `SQLiteTeamContextStore` wird
 * schon von der Aufgaben-Ausführung genutzt, und der Seiten-Fetcher ist nie
 * Firebase-gebunden gewesen. Das Modell legt die Cloud fest; die
 * Runtime erfährt es per Firestore-Listener (siehe `RuntimeAssistantModel`).
 * Ohne Wert gilt das Standardmodell (siehe `resolveAssistantLanguageModel`).
 */
export async function createLocalKnowledgeBaseAssistant(
  database: RuntimeExecutor,
  modelSettings: AssistantModelSettings,
): Promise<KnowledgeBaseAssistant> {
  const {ai, model} = await resolveAssistantLanguageModel(modelSettings);
  const responder = createKnowledgeBaseAssistantResponder({
    ai,
    model,
    modelConfig: {},
    toolDependencies: {
      noteStore: new SQLiteKnowledgeBaseAssistantNoteStore(database),
      teamContextStore: new SQLiteTeamContextStore(database),
      pageFetcher: new PublicPageHtmlFetcher(new PublicPageHttpClient()),
    },
  });
  return createKnowledgeBaseAssistant(responder);
}

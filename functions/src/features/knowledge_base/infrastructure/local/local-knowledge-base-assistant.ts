import {type LocalSqlDatabase} from "../../../../shared/local/local-sql-database.js";
import {SQLiteTeamContextStore} from "../../../teams/infrastructure/local/sqlite-team-context-store.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";
import {createKnowledgeBaseAssistantResponder} from "../genkit/knowledge-base-assistant-responder.js";
import {createKnowledgeBaseAssistant} from "../genkit/knowledge-base-assistant.js";
import {type KnowledgeBaseAssistant} from "../../domain/usecases/knowledge-base-assistant.js";
import {SQLiteKnowledgeBaseAssistantNoteStore} from "./sqlite-knowledge-base-assistant-note-store.js";
import {type GenkitLanguageModelResolver} from "../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../language_models/domain/repositories/language-model-defaults-store.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";

/**
 * Alle drei Tool-Abhängigkeiten existieren bereits lokal:
 * `SQLiteKnowledgeBaseAssistantNoteStore` liest dieselbe `knowledge_notes`-
 * Tabelle wie `LocalKnowledgeNoteHttpHandler`, `SQLiteTeamContextStore` wird
 * schon von der Aufgaben-Ausführung genutzt, und der Seiten-Fetcher ist nie
 * Firebase-gebunden gewesen. Das Sprachmodell wird — wie beim
 * Aufgabenstudio-Assistenten — pro Anfrage aufgelöst, damit eine geänderte
 * Vorgabe sofort wirkt (siehe `resolveAssistantLanguageModel`).
 */
export async function createLocalKnowledgeBaseAssistant(
  database: LocalSqlDatabase,
  teamId: string,
  resolver: GenkitLanguageModelResolver,
  defaultsStore: LanguageModelDefaultsStore,
): Promise<KnowledgeBaseAssistant> {
  const {ai, model} = await resolveAssistantLanguageModel(teamId, resolver, defaultsStore);
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

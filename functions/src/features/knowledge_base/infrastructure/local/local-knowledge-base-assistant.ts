import {type RuntimeExecutor} from "../../../../db/database.js";
import {type LanguageModelDefaultsStore} from "../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type GenkitLanguageModelResolver} from "../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {resolveDefaultLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-default-language-model.js";
import {SQLiteTeamContextStore} from "../../../teams/infrastructure/local/sqlite-team-context-store.js";
import {type KnowledgeBaseAssistant} from "../../domain/usecases/knowledge-base-assistant.js";
import {createKnowledgeBaseAssistantResponder} from "../genkit/knowledge-base-assistant-responder.js";
import {createKnowledgeBaseAssistant} from "../genkit/knowledge-base-assistant.js";
import {PublicPageHtmlFetcher} from "../genkit/public-page-html-fetcher.js";
import {PublicPageHttpClient} from "../genkit/public-page-http-client.js";
import {SQLiteKnowledgeBaseAssistantNoteStore} from "./sqlite-knowledge-base-assistant-note-store.js";

/**
 * Der Wissensbasis-Agent läuft in der Runtime, damit die Notizen das Gerät
 * nie verlassen. Er nutzt das Sprachmodell des Nutzers (Standardmodell, siehe
 * `resolveDefaultLanguageModel`), nicht das der Cloud. Wird pro Anfrage
 * gebaut, damit ein geändertes Standardmodell sofort wirkt.
 */
export async function createLocalKnowledgeBaseAssistant(
  database: RuntimeExecutor,
  teamId: string,
  resolver: GenkitLanguageModelResolver,
  defaultsStore: LanguageModelDefaultsStore,
): Promise<KnowledgeBaseAssistant> {
  const {ai, model} = await resolveDefaultLanguageModel(teamId, resolver, defaultsStore);
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

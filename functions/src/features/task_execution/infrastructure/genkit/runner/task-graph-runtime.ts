import {type SkillContentReader} from "../../../../skills/domain/repositories/skill-content-reader.js";
import {type TaskRunServices} from "../../../domain/executors/node-executor.js";
import {type KnowledgeBaseStore} from "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

/** Was ein Graph-Lauf braucht: die durchgereichten Dienste ([TaskRunServices]) plus Stores und Modelle, die nur der Runner nutzt. */
export type TaskGraphRuntime = TaskRunServices & {
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  teamFileStore: TeamFileStore;
  /** Skills-Ordner für angehängte Fähigkeiten; fehlt in Umgebungen ohne Skills (Cloud, bis dort umgesetzt). */
  skillContentReader?: SkillContentReader;
  logger: ApplicationLogger;
  languageModelResolver?: GenkitLanguageModelResolver;
  languageModelDefaultsStore?: LanguageModelDefaultsStore;
};

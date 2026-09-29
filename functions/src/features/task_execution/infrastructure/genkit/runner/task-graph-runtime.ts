import {type KnowledgeBaseStore} from "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {type TeamFileContentReader} from "../../../../files/domain/repositories/team-file-content-reader.js";
import {type TaskMessageSender} from "../../../domain/repositories/task-message-sender.js";
import {type ModelInference} from "../../../../machine_learning/domain/repositories/model-inference.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {type DocumentStore} from "../../../../data/domain/repositories/document-store.js";
import {type TeamNotificationSender} from "../../../../notifications/domain/repositories/team-notification-sender.js";

export type TaskGraphRuntime = {
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  teamFileStore: TeamFileStore;
  fileContentReader: TeamFileContentReader;
  messageSender: TaskMessageSender;
  documentStore: DocumentStore;
  modelInference: ModelInference;
  teamNotificationSender: TeamNotificationSender;
  logger: ApplicationLogger;
  languageModelResolver?: GenkitLanguageModelResolver;
  languageModelDefaultsStore?: LanguageModelDefaultsStore;
};

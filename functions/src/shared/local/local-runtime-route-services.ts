import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {createSkillsModule} from "../../features/skills/infrastructure/local/skills-composition.js";
import {LanguageModelSpeech} from "../../features/speech_synthesis/domain/usecases/language-model-speech.js";
import {defaultSpeechProviders} from "../../features/speech_synthesis/infrastructure/default-speech-providers.js";
import {SQLiteFolderAncestry} from "../../features/files/infrastructure/local/sqlite-folder-ancestry.js";
import {TriggerCycleGuard} from "../../features/scheduling/domain/usecases/trigger-cycle-guard.js";
import {SQLiteTaskTriggerStore} from "../../features/scheduling/infrastructure/local/sqlite-task-trigger-store.js";
import {type LocalRuntimeWorkspaceContext} from "./local-runtime-workspace-context.js";
import path from "node:path";
import {type RuntimeDatabase} from "../../db/database.js";
import {SQLiteDocumentStore} from "../../features/data/infrastructure/local/sqlite-document-store.js";
import {SQLiteFileSettingsStore} from "../../features/files/infrastructure/local/sqlite-file-settings-store.js";
import {LocalTeamFileStore} from "../../features/files/infrastructure/local/local-team-file-store.js";
import {createLocalKnowledgeBaseAssistant} from "../../features/knowledge_base/infrastructure/local/local-knowledge-base-assistant.js";
import {CatalogGenkitLanguageModelResolver} from "../../features/language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {SQLiteLanguageModelCatalog} from "../../features/language_models/infrastructure/local/sqlite-language-model-catalog.js";
import {SQLiteLanguageModelConfigurationStore} from "../../features/language_models/infrastructure/local/sqlite-language-model-configuration-store.js";
import {SQLiteLanguageModelDefaultsStore} from "../../features/language_models/infrastructure/local/sqlite-language-model-defaults-store.js";
import {HuggingFaceModelArtifactDownloader} from "../../features/machine_learning/infrastructure/local/hugging-face-model-artifact-downloader.js";
import {LocalModelArtifactPublisher} from "../../features/machine_learning/infrastructure/local/local-model-artifact-publisher.js";
import {LocalModelArtifactUploadStore} from "../../features/machine_learning/infrastructure/local/local-model-artifact-upload-store.js";
import {type ModelCatalogRoutesOptions} from "../../features/machine_learning/infrastructure/local/local-model-catalog-routes.js";
import {
  PythonModelContractValidator,
  UnavailablePythonModelContractValidator,
} from "../../features/machine_learning/infrastructure/local/python-model-contract-validator.js";
import {SQLiteModelCatalog} from "../../features/machine_learning/infrastructure/local/sqlite-model-catalog.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {createLocalTaskBuilderAssistant} from "../../features/task_execution/infrastructure/local/local-task-builder-assistant.js";
import {SQLiteTaskDefinitionStore} from "../../features/task_execution/infrastructure/local/sqlite-task-definition-store.js";
import {type AssistantRoutesOptions} from "./local-assistant-routes.js";
import {SQLiteLocalApplicationLogStore} from "../logging/sqlite-local-application-log-store.js";
import {LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {type LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";

/**
 * Stabile Dienste der HTTP-Schicht — einmal beim Start gebaut, da sie nur
 * von Datenbank, Runtime-Verzeichnis und Umgebung abhängen, nicht vom
 * aktiven Arbeitsbereich.
 */
export function createLocalRuntimeRouteServices(options: {
  database: RuntimeDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  notifier: LocalRuntimeRealtimeNotifier;
  licenses: Pick<RuntimeLicenseService, "signedActiveLicense">;
  workspaceContext: () => LocalRuntimeWorkspaceContext;
}) {
  const {database, runtimeRoot} = options;
  const languageModelSecrets = new EncryptedSQLiteLanguageModelSecretStore(database, options.fieldCipher);
  const fileSettings = new SQLiteFileSettingsStore(database);
  const taskDefinitions = new SQLiteTaskDefinitionStore(database);
  return {
    credentials: new LocalRuntimeAccessCredentialStore(database),
    documents: new SQLiteDocumentStore(database),
    fileSettings,
    teamFiles: new LocalTeamFileStore(database, runtimeRoot, fileSettings, {
      publish: (event) => options.workspaceContext().fileEvents.publish(event),
    }),
    taskDefinitions,
    cycleGuard: new TriggerCycleGuard({
      tasks: taskDefinitions, triggers: new SQLiteTaskTriggerStore(database), folders: new SQLiteFolderAncestry(database),
    }),
    applicationLogs: new SQLiteLocalApplicationLogStore(database),
    languageModels: new SQLiteLanguageModelConfigurationStore(database, languageModelSecrets),
    languageModelDefaults: new SQLiteLanguageModelDefaultsStore(database),
    skills: createSkillsModule(runtimeRoot, options.notifier, () => options.licenses.signedActiveLicense()),
    speechVoices: new LanguageModelSpeech(new SQLiteLanguageModelCatalog(database, languageModelSecrets), defaultSpeechProviders()),
    assistants: assistantFactories(database, languageModelSecrets),
    modelCatalog: modelCatalogOptions(runtimeRoot, database, options.notifier),
  };
}

function assistantFactories(
  database: RuntimeDatabase, secrets: EncryptedSQLiteLanguageModelSecretStore,
): AssistantRoutesOptions {
  const resolver = new CatalogGenkitLanguageModelResolver(new SQLiteLanguageModelCatalog(database, secrets));
  const defaults = new SQLiteLanguageModelDefaultsStore(database);
  return {
    taskBuilderAssistant: (teamId) => createLocalTaskBuilderAssistant(teamId, resolver, defaults),
    knowledgeBaseAssistant: (teamId) => createLocalKnowledgeBaseAssistant(database, teamId, resolver, defaults),
  };
}

function modelCatalogOptions(
  runtimeRoot: string, database: RuntimeDatabase, notifier: LocalRuntimeRealtimeNotifier,
): ModelCatalogRoutesOptions {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  return {
    catalog: new SQLiteModelCatalog(database),
    artifactPublisher: new LocalModelArtifactPublisher(runtimeRoot),
    uploadStore: new LocalModelArtifactUploadStore(runtimeRoot),
    contractValidator: sidecarUrl ? new PythonModelContractValidator(sidecarUrl) : new UnavailablePythonModelContractValidator(),
    notifier,
    artifactDownloader: new HuggingFaceModelArtifactDownloader(
      path.join(runtimeRoot, "model-cache"), process.env.HF_TOKEN?.trim() || undefined,
    ),
  };
}

import {connectionRoutes} from "../../features/connections/infrastructure/local/local-connection-routes.js";
import {employeeRoutes} from "../../features/employees/infrastructure/local/local-employee-routes.js";
import {skillCatalogRoutes} from "../../features/skills/infrastructure/local/local-skill-catalog-routes.js";
import {skillRoutes} from "../../features/skills/infrastructure/local/local-skill-routes.js";
import {speechVoiceRoutes} from "../../features/speech_synthesis/infrastructure/local/speech-voice-routes.js";
import {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type RuntimeDatabase} from "../../db/database.js";
import {type MailConnectorListCache} from "../../features/communication/infrastructure/local/mail-connector-list-cache.js";
import {mailRelayRoutes} from "../../features/communication/infrastructure/local/local-mail-relay-routes.js";
import {dataRoutes} from "../../features/data/infrastructure/local/local-data-routes.js";
import {fileSettingsRoutes} from "../../features/files/infrastructure/local/local-file-settings-routes.js";
import {fileResourceRoutes} from "../../features/files/infrastructure/local/local-file-resource-routes.js";
import {knowledgeNoteRoutes} from "../../features/knowledge_base/infrastructure/local/local-knowledge-note-routes.js";
import {languageModelDefaultsRoutes} from "../../features/language_models/infrastructure/local/local-language-model-defaults-routes.js";
import {languageModelRoutes} from "../../features/language_models/infrastructure/local/local-language-model-routes.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {modelCatalogRoutes} from "../../features/machine_learning/infrastructure/local/local-model-catalog-routes.js";
import {pushDeviceRoutes} from "../../features/notifications/infrastructure/local/local-push-device-routes.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {taskTriggerRoutes} from "../../features/scheduling/infrastructure/local/local-task-trigger-routes.js";
import {taskActivityRoutes} from "../../features/task_execution/infrastructure/local/local-task-activity-routes.js";
import {taskDefinitionRoutes} from "../../features/task_execution/infrastructure/local/local-task-definition-routes.js";
import {taskRunRoutes} from "../../features/task_execution/infrastructure/local/local-task-run-routes.js";
import {workspaceTransferRoutesOptions} from "../../features/workspace_transfer/infrastructure/local/workspace-transfer-composition.js";
import {workspaceTransferRoutes} from "../../features/workspace_transfer/infrastructure/local/local-workspace-transfer-routes.js";
import {applicationLogRoutes} from "../logging/local-application-log-routes.js";
import {assistantRoutes} from "./local-assistant-routes.js";
import {registerLocalRuntimeAccessHooks} from "./local-runtime-access-hooks.js";
import {createLoginAttemptLimiter} from "./local-runtime-login-rate-limiter.js";
import {loginRoutes} from "./local-runtime-login-routes.js";
import {passwordRoutes} from "./local-runtime-password-routes.js";
import {type LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {type LocalRuntimeRealtimeConnections} from "./local-runtime-realtime-connections.js";
import {realtimeTicketRoutes} from "./local-runtime-realtime-ticket-routes.js";
import {type LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";
import {mailRelayFromEnvironment, pushRelayFromEnvironment} from "./local-runtime-relays.js";
import {createLocalRuntimeRouteServices} from "./local-runtime-route-services.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {sessionRoutes} from "./local-runtime-session-routes.js";
import {setupRoutes} from "./local-runtime-setup-routes.js";
import {registerWorkspaceContext, type LocalRuntimeWorkspaceContext} from "./local-runtime-workspace-context.js";

export type LocalRuntimeApiDependencies = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  licenses: RuntimeLicenseService;
  sessions: LocalRuntimeSessionStore;
  notifier: LocalRuntimeRealtimeNotifier;
  tickets: LocalRuntimeRealtimeTicketStore;
  realtimeConnections: LocalRuntimeRealtimeConnections;
  mailConnectors: MailConnectorListCache;
  workspaceContext: () => LocalRuntimeWorkspaceContext;
};

/**
 * Gekapselter API-Kontext: Lizenz- und Session-Hooks gelten für alle hier
 * registrierten Feature-Plugins, nicht für `/healthz`, Lizenz-Routen und Web-Build.
 */
export function localRuntimeApi(dependencies: LocalRuntimeApiDependencies): FastifyPluginAsync {
  return async (api) => {
    const services = createLocalRuntimeRouteServices({...dependencies});
    registerLocalRuntimeAccessHooks(api, dependencies.licenses, dependencies.sessions);
    registerWorkspaceContext(api, dependencies.workspaceContext);
    await registerAccessRoutes(api, dependencies, services);
    await registerFeatureRoutes(api, dependencies, services);
  };
}

type RouteServices = ReturnType<typeof createLocalRuntimeRouteServices>;

/** Einrichtung und Anmeldung (ohne Session, siehe Access-Hooks), Realtime-Tickets, Abmelden und Widerrufen. */
async function registerAccessRoutes(api: FastifyInstance, dependencies: LocalRuntimeApiDependencies, services: RouteServices) {
  await api.register(setupRoutes, {credentials: services.credentials, authorization: dependencies.licenses});
  await api.register(passwordRoutes, {credentials: services.credentials});
  await api.register(loginRoutes, {
    credentials: services.credentials, sessions: dependencies.sessions, limiter: createLoginAttemptLimiter(),
  });
  await api.register(realtimeTicketRoutes, {tickets: dependencies.tickets});
  await api.register(sessionRoutes, {sessions: dependencies.sessions, connections: dependencies.realtimeConnections});
}

async function registerFeatureRoutes(api: FastifyInstance, dependencies: LocalRuntimeApiDependencies, services: RouteServices) {
  const {database, runtimeRoot, notifier, licenses} = dependencies;
  const signedLicense = () => licenses.signedActiveLicense();
  await api.register(taskRunRoutes, {notifier});
  await api.register(taskDefinitionRoutes, {store: services.taskDefinitions, notifier, cycleGuard: services.cycleGuard});
  await api.register(taskActivityRoutes, {database});
  await api.register(taskTriggerRoutes, {database, notifier, cycleGuard: services.cycleGuard, webhookSecrets: services.languageModelSecrets});
  await api.register(pushDeviceRoutes, {signedLicense, relay: pushRelayFromEnvironment()});
  await api.register(mailRelayRoutes, {
    signedLicense, relay: mailRelayFromEnvironment(), connectorCache: dependencies.mailConnectors,
  });
  await api.register(languageModelRoutes, {store: services.languageModels, notifier});
  await api.register(connectionRoutes, {store: services.connections, client: services.connectionClient, notifier});
  await api.register(employeeRoutes, services.employees);
  await api.register(skillCatalogRoutes, services.skills.catalog);
  await api.register(skillRoutes, services.skills.routes);
  await api.register(speechVoiceRoutes, {voices: services.speechVoices});
  await api.register(languageModelDefaultsRoutes, {store: services.languageModelDefaults, notifier});
  await api.register(fileSettingsRoutes, {store: services.fileSettings, notifier});
  await api.register(dataRoutes, {store: services.documents});
  await api.register(modelCatalogRoutes, services.modelCatalog);
  await api.register(applicationLogRoutes, {store: services.applicationLogs, notifier});
  await api.register(knowledgeNoteRoutes, {database, notifier});
  await api.register(fileResourceRoutes, {database, fileStore: services.teamFiles, notifier});
  await api.register(assistantRoutes, services.assistants);
  await api.register(workspaceTransferRoutes, workspaceTransferRoutesOptions({database, runtimeRoot, notifier}));
}

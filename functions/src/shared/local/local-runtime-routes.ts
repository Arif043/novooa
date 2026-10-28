import {connectionRoutes} from "../../features/connections/infrastructure/local/local-connection-routes.js";
import {employeeRoutes} from "../../features/employees/infrastructure/local/local-employee-routes.js";
import {skillCatalogRoutes} from "../../features/skills/infrastructure/local/local-skill-catalog-routes.js";
import {skillRoutes} from "../../features/skills/infrastructure/local/local-skill-routes.js";
import {speechVoiceRoutes} from "../../features/speech_synthesis/infrastructure/local/speech-voice-routes.js";
import {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type RelayListCache} from "./relay-list-cache.js";
import {type GoogleAccountsModule} from "../../features/google_accounts/infrastructure/local/google-accounts-module.js";
import {googleAccountRoutes} from "../../features/google_accounts/infrastructure/local/local-google-account-routes.js";
import {type MailConnectorSummary} from "../../features/communication/domain/entities/mail-connector-summary.js";
import {mailRelayRoutes} from "../../features/communication/infrastructure/local/local-mail-relay-routes.js";
import {dataRoutes} from "../../features/data/infrastructure/local/local-data-routes.js";
import {fileSettingsRoutes} from "../../features/files/infrastructure/local/local-file-settings-routes.js";
import {fileMutationRoutes} from "../../features/files/infrastructure/local/local-file-mutation-routes.js";
import {fileResourceRoutes} from "../../features/files/infrastructure/local/local-file-resource-routes.js";
import {SQLiteTeamFileMutations} from "../../features/files/infrastructure/local/sqlite-team-file-mutations.js";
import {knowledgeNoteRoutes} from "../../features/knowledge_base/infrastructure/local/local-knowledge-note-routes.js";
import {languageModelDefaultsRoutes} from "../../features/language_models/infrastructure/local/local-language-model-defaults-routes.js";
import {languageModelRoutes} from "../../features/language_models/infrastructure/local/local-language-model-routes.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {modelCatalogRoutes} from "../../features/machine_learning/infrastructure/local/local-model-catalog-routes.js";
import {pushDeviceRoutes} from "../../features/notifications/infrastructure/local/local-push-device-routes.js";
import {taskTriggerRoutes} from "../../features/scheduling/infrastructure/local/local-task-trigger-routes.js";
import {taskRunGraphRoutes} from "../../features/task_execution/infrastructure/local/local-task-run-graph-routes.js";
import {taskActivityRoutes} from "../../features/task_execution/infrastructure/local/local-task-activity-routes.js";
import {taskDefinitionRoutes} from "../../features/task_execution/infrastructure/local/local-task-definition-routes.js";
import {taskRunRoutes} from "../../features/task_execution/infrastructure/local/local-task-run-routes.js";
import {scriptPackageRoutes} from "../../features/task_execution/infrastructure/local/local-script-package-routes.js";
import {workspaceTransferRoutesOptions} from "../../features/workspace_transfer/infrastructure/local/workspace-transfer-composition.js";
import {workspaceTransferRoutes} from "../../features/workspace_transfer/infrastructure/local/local-workspace-transfer-routes.js";
import {applicationLogRoutes} from "../logging/local-application-log-routes.js";
import {assistantRoutes} from "./local-assistant-routes.js";
import {registerLocalRuntimeAccessHooks} from "./local-runtime-access-hooks.js";
import {type LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {type LocalRuntimeRealtimeConnections} from "./local-runtime-realtime-connections.js";
import {realtimeTicketRoutes} from "./local-runtime-realtime-ticket-routes.js";
import {type LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";
import {mailRelayFromEnvironment, pushRelayFromEnvironment} from "./local-runtime-relays.js";
import {type LocalMlService} from "../../features/machine_learning/infrastructure/local/local-ml-service.js";
import {createLocalRuntimeRouteServices} from "./local-runtime-route-services.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {sessionRoutes} from "./local-runtime-session-routes.js";
import {pluginRoutes} from "../../features/plugins/infrastructure/local/local-plugin-routes.js";
import {accountRoutes} from "../../features/runtime_users/infrastructure/local/local-runtime-account-routes.js";
import {userRoutes} from "../../features/runtime_users/infrastructure/local/local-runtime-user-routes.js";
import {createRuntimeUsersModule} from "../../features/runtime_users/infrastructure/local/runtime-users-composition.js";
import {type LocalRuntimeHost} from "./local-runtime-host.js";
import {registerWorkspaceContext, type LocalRuntimeWorkspaceContext} from "./local-runtime-workspace-context.js";

export type LocalRuntimeApiDependencies = {
  /** Prozessweite Infrastruktur; bleibt bei einem Arbeitsbereichswechsel bestehen. */
  host: LocalRuntimeHost;
  licenses: RuntimeLicenseService;
  sessions: LocalRuntimeSessionStore;
  notifier: LocalRuntimeRealtimeNotifier;
  tickets: LocalRuntimeRealtimeTicketStore;
  realtimeConnections: LocalRuntimeRealtimeConnections;
  mailConnectors: RelayListCache<MailConnectorSummary>;
  googleAccounts: GoogleAccountsModule;
  workspaceContext: () => LocalRuntimeWorkspaceContext;
  mlService: LocalMlService | undefined;
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
    await registerAccessRoutes(api, dependencies);
    await registerFeatureRoutes(api, dependencies, services);
  };
}

type RouteServices = ReturnType<typeof createLocalRuntimeRouteServices>;

/** Einrichtung, Anmeldung, Konten (öffentlich nur, was die Access-Hooks freigeben), Realtime-Tickets, Abmelden. */
async function registerAccessRoutes(api: FastifyInstance, dependencies: LocalRuntimeApiDependencies) {
  const runtimeUsers = createRuntimeUsersModule({
    database: dependencies.host.database, fieldCipher: dependencies.host.fieldCipher,
    workspace: () => {
      const {teamId, ownerUid} = dependencies.workspaceContext();
      return {teamId, ownerUid};
    },
    sessions: dependencies.sessions, connections: dependencies.realtimeConnections, proof: dependencies.licenses,
    limit: {maxUsers: () => dependencies.licenses.activeContext()?.maxUsers ?? null}, notifier: dependencies.notifier,
  });
  await api.register(accountRoutes, runtimeUsers.account);
  await api.register(userRoutes, runtimeUsers.users);
  await api.register(realtimeTicketRoutes, {tickets: dependencies.tickets});
  await api.register(sessionRoutes, {sessions: dependencies.sessions, connections: dependencies.realtimeConnections});
}

async function registerFeatureRoutes(api: FastifyInstance, dependencies: LocalRuntimeApiDependencies, services: RouteServices) {
  const {database, runtimeRoot} = dependencies.host;
  const {notifier, licenses} = dependencies;
  const signedLicense = () => licenses.signedActiveLicense();
  await api.register(taskRunRoutes, {notifier});
  await api.register(taskDefinitionRoutes, {store: services.taskDefinitions, notifier, cycleGuard: services.cycleGuard});
  await api.register(taskActivityRoutes, {database});
  await api.register(taskRunGraphRoutes, {database});
  await api.register(taskTriggerRoutes, {database, notifier, cycleGuard: services.cycleGuard, webhookSecrets: services.languageModelSecrets});
  await api.register(pushDeviceRoutes, {signedLicense, relay: pushRelayFromEnvironment()});
  await api.register(mailRelayRoutes, {
    signedLicense, relay: mailRelayFromEnvironment(), connectorCache: dependencies.mailConnectors,
  });
  await api.register(googleAccountRoutes, {signedLicense, module: dependencies.googleAccounts});
  await api.register(languageModelRoutes, {store: services.languageModels, notifier});
  await api.register(connectionRoutes, {store: services.connections, client: services.connectionClient, notifier});
  await api.register(employeeRoutes, services.employees);
  await api.register(skillCatalogRoutes, services.skills.catalog);
  await api.register(skillRoutes, services.skills.routes);
  await api.register(speechVoiceRoutes, {voices: services.speechVoices});
  await api.register(languageModelDefaultsRoutes, {store: services.languageModelDefaults, notifier});
  await api.register(fileSettingsRoutes, {store: services.fileSettings, notifier});
  await api.register(pluginRoutes, services.plugins);
  await api.register(dataRoutes, {store: services.documents});
  await api.register(modelCatalogRoutes, services.modelCatalog);
  await api.register(scriptPackageRoutes, {jobs: services.scriptPackages});
  await api.register(applicationLogRoutes, {store: services.applicationLogs, notifier});
  await api.register(knowledgeNoteRoutes, {database, notifier});
  await api.register(fileResourceRoutes, {database, fileStore: services.teamFiles, notifier});
  await api.register(fileMutationRoutes, {database, mutations: new SQLiteTeamFileMutations(database, services.teamFiles), notifier});
  await api.register(assistantRoutes, services.assistants);
  await api.register(workspaceTransferRoutes, workspaceTransferRoutesOptions({database, runtimeRoot, notifier}));
}

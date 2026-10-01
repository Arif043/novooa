import {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type Server} from "node:http";
import {type RuntimeDatabase} from "../../db/database.js";
import {LocalMailRelayHttpHandler} from "../../features/communication/infrastructure/local/local-mail-relay-http-handler.js";
import {LocalDataHttpHandler} from "../../features/data/infrastructure/local/local-data-http-handler.js";
import {LocalFileResourceHttpHandler} from "../../features/files/infrastructure/local/local-file-resource-http-handler.js";
import {LocalKnowledgeNoteHttpHandler} from "../../features/knowledge_base/infrastructure/local/local-knowledge-note-http-handler.js";
import {LocalLanguageModelDefaultsHttpHandler} from "../../features/language_models/infrastructure/local/local-language-model-defaults-http-handler.js";
import {LocalLanguageModelHttpHandler} from "../../features/language_models/infrastructure/local/local-language-model-http-handler.js";
import {ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {LocalModelCatalogHttpHandler} from "../../features/machine_learning/infrastructure/local/local-model-catalog-http-handler.js";
import {LocalPushDeviceHttpHandler} from "../../features/notifications/infrastructure/local/local-push-device-http-handler.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {LocalTaskTriggerHttpHandler} from "../../features/scheduling/infrastructure/local/local-task-trigger-http-handler.js";
import {LocalTaskActivityHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-activity-http-handler.js";
import {LocalTaskDefinitionHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-definition-http-handler.js";
import {LocalTaskRunHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-run-http-handler.js";
import {LocalApplicationLogHttpHandler} from "../logging/local-application-log-http-handler.js";
import {LocalAssistantHttpHandler} from "./local-assistant-http-handler.js";
import {registerLocalRuntimeAccessHooks} from "./local-runtime-access-hooks.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {type LocalRuntimeControllers} from "./local-runtime-composition.js";
import {type LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {registerRuntimeLicenseRoutes} from "./local-runtime-license-routes.js";
import {LocalRuntimeLoginHttpHandler} from "./local-runtime-login-http-handler.js";
import {attachLocalRuntimeRealtimeServer} from "./local-runtime-realtime-server.js";
import {LocalRuntimeRealtimeTicketHttpHandler} from "./local-runtime-realtime-ticket-http-handler.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {LocalRuntimeSetupHttpHandler} from "./local-runtime-setup-http-handler.js";

type BootstrapOptions = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  licenses: RuntimeLicenseService;
  cors: LocalRuntimeCorsPolicy;
  webDirectory: string | undefined;
  port: number;
};

export async function bootstrapLocalRuntime(options: BootstrapOptions): Promise<{
  server: Server; application: LocalRuntimeApplication; closeHttp: () => Promise<void>;
}> {
  const setupCode = new LocalRuntimeSetupCode();
  const sessions = new LocalRuntimeSessionStore(options.database);
  const application = applicationFor(options, setupCode, sessions);
  try {
    const restored = await options.licenses.restore();
    if (restored !== null) await application.activate(restored);
    const http = await listenForRequests(options, application, sessions);
    reportStarted(options.port, setupCode);
    return {server: http.server, application, closeHttp: () => http.close()};
  } catch (error) {
    await application.stop();
    throw error;
  }
}

function applicationFor(
  options: BootstrapOptions, setupCode: LocalRuntimeSetupCode, sessions: LocalRuntimeSessionStore,
): LocalRuntimeApplication {
  const {database, runtimeRoot, fieldCipher, licenses} = options;
  return new LocalRuntimeApplication({
    database, runtimeRoot, fieldCipher, setupCode, sessions,
    isLicenseActive: () => licenses.activeContext() !== null,
    signedLicense: () => licenses.signedActiveLicense(),
    activeLicenseActivation: () => licenses.activeActivation(),
  });
}

async function listenForRequests(
  options: BootstrapOptions, application: LocalRuntimeApplication, sessions: LocalRuntimeSessionStore,
): Promise<FastifyInstance> {
  const http = createLocalRuntimeHttpServer(
    runtimeRoutes(options, application, sessions), options.webDirectory, options.cors,
  );
  attachRealtimeLifecycle(http, application, options.cors);
  try {
    await http.listen({port: options.port, host: "0.0.0.0"});
    return http;
  } catch (error) {
    await http.close();
    throw error;
  }
}

function runtimeRoutes(
  options: BootstrapOptions, application: LocalRuntimeApplication, sessions: LocalRuntimeSessionStore,
): FastifyPluginAsync {
  return async (routes) => {
    const activate = new ActivateRuntime(options.licenses, (context) => application.activate(context));
    registerRuntimeLicenseRoutes(routes, options.licenses, activate);
    routes.register(async (api) => {
      registerLocalRuntimeAccessHooks(api, options.licenses, sessions);
      registerLocalRuntimeRoutes(api, () => application.controllers());
    });
  };
}

function attachRealtimeLifecycle(
  http: FastifyInstance, application: LocalRuntimeApplication, cors: LocalRuntimeCorsPolicy,
): void {
  const realtime = attachLocalRuntimeRealtimeServer(http.server, application, cors);
  http.addHook("preClose", async () => {
    for (const client of realtime.clients) client.terminate();
    await new Promise<void>((resolve) => realtime.close(() => resolve()));
  });
}

function registerLocalRuntimeRoutes(http: FastifyInstance, current: () => LocalRuntimeControllers): void {
  LocalRuntimeSetupHttpHandler.registerRoutes(http, () => current().setup);
  LocalRuntimeLoginHttpHandler.registerRoutes(http, () => current().login);
  LocalRuntimeRealtimeTicketHttpHandler.registerRoutes(http, () => current().realtimeTickets);
  LocalTaskRunHttpHandler.registerRoutes(http, () => current().taskRuns);
  LocalPushDeviceHttpHandler.registerRoutes(http, () => current().pushDevices);
  LocalMailRelayHttpHandler.registerRoutes(http, () => current().mailRelay);
  LocalTaskDefinitionHttpHandler.registerRoutes(http, () => current().tasks);
  LocalLanguageModelHttpHandler.registerRoutes(http, () => current().languageModels);
  LocalLanguageModelDefaultsHttpHandler.registerRoutes(http, () => current().languageModelDefaults);
  LocalDataHttpHandler.registerRoutes(http, () => current().data);
  LocalModelCatalogHttpHandler.registerRoutes(http, () => current().modelCatalog);
  LocalTaskActivityHttpHandler.registerRoutes(http, () => current().activities);
  LocalApplicationLogHttpHandler.registerRoutes(http, () => current().logs);
  LocalKnowledgeNoteHttpHandler.registerRoutes(http, () => current().knowledge);
  LocalTaskTriggerHttpHandler.registerRoutes(http, () => current().triggers);
  LocalFileResourceHttpHandler.registerRoutes(http, () => current().files);
  LocalAssistantHttpHandler.registerRoutes(http, () => current().assistants);
}

function reportStarted(port: number, setupCode: LocalRuntimeSetupCode): void {
  // Host-Zugriff auf die Logs ist dieselbe Vertrauensbasis wie ein Neustart,
  // der den prozessgebundenen Setup-Code ebenfalls neu erzeugt.
  console.info(JSON.stringify({event: "local_runtime.started", port, setupCode: setupCode.current}));
}

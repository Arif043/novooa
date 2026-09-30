import {type Server} from "node:http";
import {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {registerLocalRuntimeAccessHooks} from "./local-runtime-access-hooks.js";
import {registerRuntimeLicenseRoutes} from "./local-runtime-license-routes.js";
import {registerLocalRuntimeRoutes} from "./local-runtime-composition.js";
import {ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {attachLocalRuntimeRealtimeServer} from "./local-runtime-realtime-server.js";
import {type LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";

type BootstrapOptions = {
  database: SqliteLocalSqlDatabase;
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

function reportStarted(port: number, setupCode: LocalRuntimeSetupCode): void {
  // Host-Zugriff auf die Logs ist dieselbe Vertrauensbasis wie ein Neustart,
  // der den prozessgebundenen Setup-Code ebenfalls neu erzeugt.
  console.info(JSON.stringify({event: "local_runtime.started", port, setupCode: setupCode.current}));
}

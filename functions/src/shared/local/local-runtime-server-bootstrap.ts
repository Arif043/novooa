import {type Server} from "node:http";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {createLocalRuntimeAccessPipeline} from "./local-runtime-access-pipeline.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {attachLocalRuntimeRealtimeServer} from "./local-runtime-realtime-server.js";
import {type LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {type LocalRuntimeStaticFiles} from "./local-runtime-static-files.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";

type BootstrapOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  licenses: RuntimeLicenseService;
  cors: LocalRuntimeCorsPolicy;
  webFiles: LocalRuntimeStaticFiles | undefined;
  port: number;
};

export async function bootstrapLocalRuntime(options: BootstrapOptions): Promise<{
  server: Server; application: LocalRuntimeApplication;
}> {
  const setupCode = new LocalRuntimeSetupCode();
  const sessions = new LocalRuntimeSessionStore(options.database);
  const application = applicationFor(options, setupCode, sessions);
  try {
    const restored = await options.licenses.restore();
    if (restored !== null) await application.activate(restored);
    const server = await listenForRequests(options, application, sessions);
    reportStarted(options.port, setupCode);
    return {server, application};
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
): Promise<Server> {
  const server = createLocalRuntimeHttpServer(
    createLocalRuntimeAccessPipeline(options.licenses, sessions, application), options.webFiles, options.cors,
  );
  attachLocalRuntimeRealtimeServer(server, application, options.cors);
  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(options.port, "0.0.0.0", resolve);
  });
  return server;
}

function reportStarted(port: number, setupCode: LocalRuntimeSetupCode): void {
  // Host-Zugriff auf die Logs ist dieselbe Vertrauensbasis wie ein Neustart,
  // der den prozessgebundenen Setup-Code ebenfalls neu erzeugt.
  console.info(JSON.stringify({event: "local_runtime.started", port, setupCode: setupCode.current}));
}

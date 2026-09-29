import {type Server} from "node:http";
import {readFileSync} from "node:fs";
import {join, resolve} from "node:path";
import {
  DevelopmentRuntimeLicenseService,
  GatewayRuntimeLicenseService,
  type RuntimeLicenseService,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {FileRuntimeLicenseStore} from "../../features/licensing/infrastructure/local/file-local-runtime-license-store.js";
import {HttpRuntimeLicenseGatewayClient} from "../../features/licensing/infrastructure/local/local-runtime-license-gateway-client.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {RuntimeLicenseMiddleware} from "./local-runtime-license-middleware.js";
import {attachLocalRuntimeRealtimeServer} from "./local-runtime-realtime-server.js";
import {localRuntimeMasterKeyFrom} from "./local-runtime-master-key.js";
import {LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {LocalRuntimeStaticFiles} from "./local-runtime-static-files.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {CredentialCipher} from "../../features/communication/infrastructure/security/credential-cipher.js";

void startLocalRuntime().catch(reportStartupFailure);

async function startLocalRuntime(): Promise<void> {
  const runtimeRoot = requiredEnvironment("LOCAL_RUNTIME_ROOT");
  const localMasterKey = await localRuntimeMasterKeyFrom(
    requiredEnvironment("LOCAL_RUNTIME_MASTER_KEY_FILE"),
  );
  const database = await openLocalRuntimeDatabase({
    databasePath: join(runtimeRoot, "novooa.sqlite"),
    migrationsDirectory: migrationsDirectory(),
  });
  try {
    const licenses = licenseServiceFor(runtimeRoot, localMasterKey);
    // Prozessweit: beide Setup-Wege teilen denselben Code, und er verfällt
    // mit dem Prozess — es gibt kein Geheimnis at rest.
    const setupCode = new LocalRuntimeSetupCode();
    const application = new LocalRuntimeApplication({
      database,
      runtimeRoot,
      localMasterKey,
      setupCode,
      isLicenseActive: () => licenses.activeContext() !== null,
      signedLicense: () => licenses.signedActiveLicense(),
      activeLicenseActivation: () => licenses.activeActivation(),
    });
    const restored = await licenses.restore();
    if (restored !== null) await application.activate(restored);
    const cors = LocalRuntimeCorsPolicy.fromEnvironment();
    const server = createLocalRuntimeHttpServer(
      new RuntimeLicenseMiddleware(licenses, application),
      webApplicationFiles(),
      cors,
    );
    attachLocalRuntimeRealtimeServer(server, application, cors);
    const port = configuredPort();
    await listen(server, port);
    registerShutdown([server], database, application);
    // Der Code steht bewusst im Start-Log: `docker compose logs` zu lesen
    // setzt Host-Zugriff voraus — dieselbe Vertrauensbasis wie ein
    // Container-Neustart, mit dem sich ein verlorener Code jederzeit neu
    // erzeugen lässt.
    console.info(JSON.stringify({
      event: "local_runtime.started",
      port,
      setupCode: setupCode.current,
    }));
  } catch (error) {
    database.close();
    throw error;
  }
}

function migrationsDirectory(): string {
  return process.env.LOCAL_RUNTIME_MIGRATIONS_DIRECTORY
    ?? resolve(__dirname, "../../../../local-runtime/migrations");
}

function configuredPort(): number {
  return portFromEnvironment("PORT", "8080", "PORT");
}

/**
 * Das Flutter-Web-Build, das die Runtime unter ihrer eigenen Herkunft
 * ausliefert. Ohne gesetztes Verzeichnis bleibt die Runtime eine reine
 * API — bestehende Installationen verhalten sich unverändert.
 */
function webApplicationFiles(): LocalRuntimeStaticFiles | undefined {
  const directory = process.env.LOCAL_RUNTIME_WEB_DIRECTORY;
  if (directory === undefined || directory.trim().length === 0) return undefined;
  return new LocalRuntimeStaticFiles(directory);
}

function portFromEnvironment(name: string, fallback: string, label: string): number {
  const port = Number(process.env[name] ?? fallback);
  if (Number.isSafeInteger(port) && port > 0 && port <= 65535) return port;
  throw new Error(`Der ${label} für die lokale Runtime ist ungültig.`);
}

function requiredEnvironment(name: string): string {
  const value = process.env[name]?.trim();
  if (value) return value;
  throw new Error(`${name} fehlt.`);
}

function licenseServiceFor(runtimeRoot: string, localMasterKey: string): RuntimeLicenseService {
  if (process.env.NOVOOA_LOCAL_DEVELOPMENT === "true") {
    return new DevelopmentRuntimeLicenseService({
      licenseId: "development-license",
      licenseName: "Entwicklungsumgebung",
      workspaceId: optionalEnvironment("LOCAL_RUNTIME_TEAM_ID") ?? "local-team",
      expiresAt: "2099-01-01T00:00:00.000Z",
    });
  }
  return new GatewayRuntimeLicenseService(
    new FileRuntimeLicenseStore(
      runtimeRoot,
      new CredentialCipher(localMasterKey, "LOCAL_RUNTIME_MASTER_KEY"),
    ),
    new HttpRuntimeLicenseGatewayClient(
      requiredEnvironment("LOCAL_RUNTIME_LICENSE_GATEWAY_URL"),
    ),
    licensePublicKey(),
  );
}

function licensePublicKey(): string {
  const file = optionalEnvironment("LOCAL_RUNTIME_LICENSE_PUBLIC_KEY_FILE");
  if (file) return readFileSync(file, "utf8").trim();
  return requiredEnvironment("LOCAL_RUNTIME_LICENSE_PUBLIC_KEY");
}

function optionalEnvironment(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value && value.length > 0 ? value : undefined;
}

function listen(server: Server, port: number): Promise<void> {
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, "0.0.0.0", resolve);
  });
}

function registerShutdown(
  servers: Server[],
  database: SqliteLocalSqlDatabase,
  application: LocalRuntimeApplication,
): void {
  let closing = false;
  const shutdown = () => {
    if (closing) return;
    closing = true;
    Promise.all(servers.map((server) => new Promise<void>((resolve) => server.close(() => resolve()))))
      .then(() => closeRuntime(database, application))
      .catch(() => closeRuntime(database, application));
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

async function closeRuntime(
  database: SqliteLocalSqlDatabase,
  application: LocalRuntimeApplication,
): Promise<void> {
  await application.stop();
  database.close();
  process.exit(0);
}

function reportStartupFailure(error: unknown): void {
  const message = errorMessage(error);
  console.error(JSON.stringify({event: "local_runtime.start_failed", message}));
  process.exitCode = 1;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

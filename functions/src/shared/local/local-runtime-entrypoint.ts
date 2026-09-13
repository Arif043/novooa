import {type Server} from "node:http";
import {readFileSync} from "node:fs";
import {join, resolve} from "node:path";
import {
  DevelopmentLocalRuntimeLicenseService,
  GatewayLocalRuntimeLicenseService,
  type LocalRuntimeLicenseService,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {FileLocalRuntimeLicenseStore} from "../../features/licensing/infrastructure/local/file-local-runtime-license-store.js";
import {HttpLocalRuntimeLicenseGatewayClient} from "../../features/licensing/infrastructure/local/local-runtime-license-gateway-client.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {LocalRuntimeLicenseHttpHandler} from "./local-runtime-license-http-handler.js";
import {localRuntimeMasterKeyFrom} from "./local-runtime-master-key.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";

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
    const licenses = licenseServiceFor(runtimeRoot);
    const application = new LocalRuntimeApplication({
      database,
      runtimeRoot,
      localMasterKey,
      isLicenseActive: () => licenses.activeContext() !== null,
      signedLicense: () => licenses.signedActiveLicense(),
    });
    const restored = await licenses.restore();
    if (restored !== null) await application.activate(restored);
    const server = createLocalRuntimeHttpServer(
      new LocalRuntimeLicenseHttpHandler(licenses, application),
    );
    const port = configuredPort();
    await listen(server, port);
    registerShutdown(server, database, application);
    console.info(JSON.stringify({event: "local_runtime.started", port}));
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
  const port = Number(process.env.PORT ?? "8080");
  if (Number.isSafeInteger(port) && port > 0 && port <= 65535) return port;
  throw new Error("Der PORT für die lokale Runtime ist ungültig.");
}

function requiredEnvironment(name: string): string {
  const value = process.env[name]?.trim();
  if (value) return value;
  throw new Error(`${name} fehlt.`);
}

function licenseServiceFor(runtimeRoot: string): LocalRuntimeLicenseService {
  if (process.env.NOVOOA_LOCAL_DEVELOPMENT === "true") {
    return new DevelopmentLocalRuntimeLicenseService({
      licenseId: "development-license",
      workspaceId: optionalEnvironment("LOCAL_RUNTIME_TEAM_ID") ?? "local-team",
      expiresAt: "2099-01-01T00:00:00.000Z",
    });
  }
  return new GatewayLocalRuntimeLicenseService(
    new FileLocalRuntimeLicenseStore(runtimeRoot),
    new HttpLocalRuntimeLicenseGatewayClient(
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
  server: Server,
  database: SqliteLocalSqlDatabase,
  application: LocalRuntimeApplication,
): void {
  let closing = false;
  const shutdown = () => {
    if (closing) return;
    closing = true;
    server.close(() => void closeRuntime(database, application));
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

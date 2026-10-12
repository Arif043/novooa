import {readFileSync} from "node:fs";
import {join, resolve} from "node:path";
import {type RuntimeDatabase} from "../../db/database.js";
import {FileRuntimeLicenseStore} from "../../features/licensing/infrastructure/local/file-local-runtime-license-store.js";
import {HttpRuntimeLicenseGatewayClient} from "../../features/licensing/infrastructure/local/local-runtime-license-gateway-client.js";
import {
  DevelopmentRuntimeLicenseService,
  GatewayRuntimeLicenseService,
  type RuntimeLicenseService,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {UpgradeRuntimeSecretFormat} from "../../features/runtime_security/infrastructure/upgrade-runtime-secret-format.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {localRuntimeMasterKeyFrom} from "./local-runtime-master-key.js";
import {acquireLocalRuntimeProcessLock} from "./local-runtime-process-lock.js";
import {LocalRuntimeSecurity} from "./local-runtime-security.js";
import {bootstrapLocalRuntime} from "./local-runtime-server-bootstrap.js";

void startLocalRuntime().catch(reportStartupFailure);

async function startLocalRuntime(): Promise<void> {
  const runtimeRoot = requiredEnvironment("LOCAL_RUNTIME_ROOT");
  const release = await acquireLocalRuntimeProcessLock(runtimeRoot);
  try {
    await startLockedRuntime(runtimeRoot, release);
  } catch (error) {
    await release();
    throw error;
  }
}

async function startLockedRuntime(runtimeRoot: string, release: () => Promise<void>): Promise<void> {
  const localKeyring = await localRuntimeMasterKeyFrom(
    requiredEnvironment("LOCAL_RUNTIME_MASTER_KEY_FILE"),
  );
  const database = await preparedRuntimeDatabase(runtimeRoot, localKeyring);
  const security = new LocalRuntimeSecurity(requiredEnvironment("LOCAL_RUNTIME_MASTER_KEY_FILE"), localKeyring, database, runtimeRoot);
  try {
    const {closeHttp, application} = await bootstrapLocalRuntime({
      database, runtimeRoot, fieldCipher: security.cipher, secretFileAccess: security.licenseAccess,
      licenses: licenseServiceFor(runtimeRoot, security),
      cors: LocalRuntimeCorsPolicy.fromEnvironment(), webDirectory: webApplicationDirectory(), port: configuredPort(),
    });
    security.start();
    registerShutdown(closeHttp, database, application, security, release);
  } catch (error) {
    database.$client.close();
    throw error;
  }
}

async function preparedRuntimeDatabase(runtimeRoot: string, keyring: string): Promise<RuntimeDatabase> {
  const database = await runtimeDatabase(runtimeRoot);
  try {
    await new UpgradeRuntimeSecretFormat(database, runtimeRoot, keyring).execute();
    return database;
  } catch (error) {
    database.$client.close();
    throw error;
  }
}

function runtimeDatabase(runtimeRoot: string): Promise<RuntimeDatabase> {
  return openLocalRuntimeDatabase({
    databasePath: join(runtimeRoot, "novooa.sqlite"), migrationsDirectory: migrationsDirectory(),
  });
}

function migrationsDirectory(): string {
  return process.env.LOCAL_RUNTIME_MIGRATIONS_DIRECTORY
    ?? resolve(__dirname, "../../../drizzle");
}

function configuredPort(): number {
  return portFromEnvironment("PORT", "8080", "PORT");
}

/**
 * Das Flutter-Web-Build, das die Runtime unter ihrer eigenen Herkunft
 * ausliefert. Ohne gesetztes Verzeichnis bleibt die Runtime eine reine
 * API — bestehende Installationen verhalten sich unverändert.
 */
function webApplicationDirectory(): string | undefined {
  const directory = process.env.LOCAL_RUNTIME_WEB_DIRECTORY;
  if (directory === undefined || directory.trim().length === 0) return undefined;
  return directory;
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

function licenseServiceFor(runtimeRoot: string, security: LocalRuntimeSecurity): RuntimeLicenseService {
  if (process.env.NOVOOA_LOCAL_DEVELOPMENT === "true") {
    return developmentLicenseService();
  }
  return new GatewayRuntimeLicenseService(
    new FileRuntimeLicenseStore(
      runtimeRoot,
      security.cipher, security.licenseAccess,
    ),
    new HttpRuntimeLicenseGatewayClient(
      requiredEnvironment("LOCAL_RUNTIME_LICENSE_GATEWAY_URL"),
    ),
    licensePublicKey(),
  );
}

function developmentLicenseService(): RuntimeLicenseService {
  return new DevelopmentRuntimeLicenseService({
    licenseId: "development-license", licenseName: "Entwicklungsumgebung",
    workspaceId: optionalEnvironment("LOCAL_RUNTIME_TEAM_ID") ?? "local-team",
    expiresAt: "2099-01-01T00:00:00.000Z",
  });
}

/** Öffentlich und für alle Runtimes gleich, deshalb Teil des Builds (`functions/keys`) statt Konfiguration. */
function licensePublicKey(): string {
  return readFileSync(resolve(__dirname, "../../../keys/runtime-license-public-key.pem"), "utf8").trim();
}

function optionalEnvironment(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value && value.length > 0 ? value : undefined;
}

function registerShutdown(
  closeHttp: () => Promise<void>,
  database: RuntimeDatabase,
  application: LocalRuntimeApplication,
  security: LocalRuntimeSecurity,
  release: () => Promise<void>,
): void {
  let closing = false;
  const shutdown = () => {
    if (closing) return;
    closing = true;
    closeHttp()
      .then(() => closeRuntime(database, application, security, release))
      .catch(reportStartupFailure);
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

async function closeRuntime(
  database: RuntimeDatabase,
  application: LocalRuntimeApplication,
  security: LocalRuntimeSecurity,
  release: () => Promise<void>,
): Promise<void> {
  await security.stop();
  await application.stop();
  database.$client.close();
  await release();
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

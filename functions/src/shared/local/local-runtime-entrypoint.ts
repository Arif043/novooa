import {type Server} from "node:http";
import {join, resolve} from "node:path";
import {createLocalRuntimeComposition} from "./local-runtime-composition.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {
  ensureLocalRuntimeWorkspace,
  type LocalRuntimeWorkspace,
} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {type PollingTaskRunWorker} from "../../features/task_execution/infrastructure/local/polling-task-run-worker.js";

void startLocalRuntime().catch(reportStartupFailure);

async function startLocalRuntime(): Promise<void> {
  const runtimeRoot = requiredEnvironment("LOCAL_RUNTIME_ROOT");
  const database = await openLocalRuntimeDatabase({
    databasePath: join(runtimeRoot, "novooa.sqlite"),
    migrationsDirectory: migrationsDirectory(),
  });
  try {
    const workspace = workspaceFromEnvironment();
    await ensureLocalRuntimeWorkspace(database, workspace);
    const runtime = createLocalRuntimeComposition({database, runtimeRoot, workspace});
    const server = createLocalRuntimeHttpServer(runtime.requestHandler);
    const port = configuredPort();
    await listen(server, port);
    runtime.taskRunWorker.start();
    registerShutdown(server, database, runtime.taskRunWorker);
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

function workspaceFromEnvironment(): LocalRuntimeWorkspace {
  return {
    userId: optionalEnvironment("LOCAL_RUNTIME_USER_ID") ?? "local-user",
    teamId: optionalEnvironment("LOCAL_RUNTIME_TEAM_ID") ?? "local-team",
    teamName: optionalEnvironment("LOCAL_RUNTIME_TEAM_NAME") ?? "Lokaler Arbeitsbereich",
  };
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
  taskRunWorker: PollingTaskRunWorker,
): void {
  let closing = false;
  const shutdown = () => {
    if (closing) return;
    closing = true;
    server.close(() => void closeRuntime(database, taskRunWorker));
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

async function closeRuntime(
  database: SqliteLocalSqlDatabase,
  taskRunWorker: PollingTaskRunWorker,
): Promise<void> {
  await taskRunWorker.stop();
  database.close();
  process.exit(0);
}

function reportStartupFailure(error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  console.error(JSON.stringify({event: "local_runtime.start_failed", message}));
  process.exitCode = 1;
}

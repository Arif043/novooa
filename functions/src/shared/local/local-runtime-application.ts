import {type LocalRuntimeLicenseContext} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {createLocalRuntimeComposition, type LocalRuntimeComposition} from "./local-runtime-composition.js";
import {type LocalRuntimeRequest, type LocalRuntimeRequestHandler, type LocalRuntimeResponse} from "./local-runtime-http-server.js";
import {ensureLocalRuntimeWorkspace, type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";

export type LocalRuntimeApplicationOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  isLicenseActive: () => boolean;
};

export class LocalRuntimeApplication implements LocalRuntimeRequestHandler {
  private runtime: LocalRuntimeComposition | undefined;
  private workspace: LocalRuntimeWorkspace | undefined;

  constructor(private readonly options: LocalRuntimeApplicationOptions) {}

  async activate(context: LocalRuntimeLicenseContext): Promise<void> {
    const workspace = workspaceFrom(context);
    if (sameWorkspace(this.workspace, workspace)) return;
    await this.stopRuntime();
    await ensureLocalRuntimeWorkspace(this.options.database, workspace);
    this.workspace = workspace;
    this.runtime = createLocalRuntimeComposition({
      ...this.options,
      workspace,
      isLicenseActive: this.options.isLicenseActive,
    });
    this.runtime.taskRunWorker.start();
    this.runtime.taskTriggerWorker.start();
  }

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    return this.runtime?.requestHandler.handle(request) ?? null;
  }

  async stop(): Promise<void> {
    await this.stopRuntime();
  }

  private async stopRuntime(): Promise<void> {
    if (this.runtime === undefined) return;
    await this.runtime.taskTriggerWorker.stop();
    await this.runtime.taskRunWorker.stop();
    this.runtime = undefined;
  }
}

function workspaceFrom(context: LocalRuntimeLicenseContext): LocalRuntimeWorkspace {
  return {
    userId: `license-${context.licenseId}`,
    teamId: context.workspaceId,
    teamName: "Lokaler Arbeitsbereich",
  };
}

function sameWorkspace(
  current: LocalRuntimeWorkspace | undefined,
  next: LocalRuntimeWorkspace,
): boolean {
  return current?.teamId === next.teamId && current.userId === next.userId;
}

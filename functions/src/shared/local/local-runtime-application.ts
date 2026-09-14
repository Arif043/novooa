import {type RuntimeLicenseContext} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {createLocalRuntimeComposition, type LocalRuntimeComposition} from "./local-runtime-composition.js";
import {type LocalRuntimeRequest, type LocalRuntimeRequestHandler, type LocalRuntimeResponse} from "./local-runtime-http-server.js";
import {ensureLocalRuntimeWorkspace, type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";

export type LocalRuntimeApplicationOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  localMasterKey: string;
  isLicenseActive: () => boolean;
  signedLicense: () => SignedRuntimeLicense | null;
};

export class LocalRuntimeApplication implements LocalRuntimeRequestHandler {
  private runtime: LocalRuntimeComposition | undefined;
  private workspace: LocalRuntimeWorkspace | undefined;

  constructor(private readonly options: LocalRuntimeApplicationOptions) {}

  async activate(context: RuntimeLicenseContext): Promise<void> {
    const workspace = workspaceFrom(context);
    if (sameWorkspace(this.workspace, workspace)) return;
    await this.stopRuntime();
    await ensureLocalRuntimeWorkspace(this.options.database, workspace);
    this.workspace = workspace;
    this.runtime = createLocalRuntimeComposition({
      ...this.options,
      workspace,
      isLicenseActive: this.options.isLicenseActive,
      signedLicense: this.options.signedLicense,
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
    await this.runtime.applicationLogger.flush();
    this.runtime = undefined;
  }
}

function workspaceFrom(context: RuntimeLicenseContext): LocalRuntimeWorkspace {
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

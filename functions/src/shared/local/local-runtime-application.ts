import {type RuntimeLicenseContext} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeLicenseActivation} from "../../features/licensing/domain/entities/runtime-license-activation.js";
import {createLocalRuntimeComposition, type LocalRuntimeComposition} from "./local-runtime-composition.js";
import {type LocalRuntimeRequest, type LocalRuntimeRequestHandler, type LocalRuntimeResponse} from "./local-runtime-http-server.js";
import {type LocalRuntimeRealtimeGateway} from "./local-runtime-realtime-server.js";
import {type LocalRuntimeRealtimeSubscriber} from "./local-runtime-realtime-notifier.js";
import {ensureLocalRuntimeWorkspace, type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {type LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";

export type LocalRuntimeApplicationOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  setupCode: LocalRuntimeSetupCode;
  sessions: LocalRuntimeSessionStore;
  isLicenseActive: () => boolean;
  signedLicense: () => SignedRuntimeLicense | null;
  activeLicenseActivation: () => RuntimeLicenseActivation | null;
};

export class LocalRuntimeApplication
implements LocalRuntimeRequestHandler, LocalRuntimeRealtimeGateway {
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
      activeLicenseActivation: this.options.activeLicenseActivation,
    });
    this.runtime.taskRunWorker.start();
    this.runtime.taskTriggerWorker.start();
    this.runtime.mailRelayWorker?.start();
    await this.startFirebaseWakeups();
  }

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    return this.runtime?.requestHandler.handle(request) ?? null;
  }

  /**
   * Vor der Lizenzaktivierung (kein `this.runtime`) gibt es nichts zu
   * konsumieren — ein Ticket kann dann per Definition nie gültig sein.
   */
  consumeRealtimeTicket(ticket: string): boolean {
    return this.runtime?.realtimeTicketStore.consume(ticket) ?? false;
  }

  subscribeRealtime(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void {
    this.runtime?.realtimeNotifier.subscribe(topic, subscriber);
  }

  unsubscribeRealtime(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void {
    this.runtime?.realtimeNotifier.unsubscribe(topic, subscriber);
  }

  async stop(): Promise<void> {
    await this.stopRuntime();
  }

  private async stopRuntime(): Promise<void> {
    if (this.runtime === undefined) return;
    await this.runtime.taskTriggerWorker.stop();
    await this.runtime.taskRunWorker.stop();
    await this.runtime.mailRelayWorker?.stop();
    await this.runtime.firebaseSession?.stop();
    await this.runtime.applicationLogger.flush();
    this.runtime = undefined;
  }

  private async startFirebaseWakeups(): Promise<void> {
    const runtime = this.runtime;
    const activation = this.options.activeLicenseActivation();
    if (runtime?.firebaseSession === undefined || activation === null) return;
    try {
      await runtime.firebaseSession.start(activation);
      runtime.firebaseSession.listenForWakeups(
        activation.license.payload.licenseId,
        () => {
          void runtime.mailRelayWorker?.processOnce().catch((error) =>
            runtime.applicationLogger.exception(
              "local_runtime.firebase_wakeup_processing_failed", error,
              {licenseId: activation.license.payload.licenseId},
            ));
        },
        (error) => {
          runtime.applicationLogger.exception(
            "local_runtime.firebase_wakeup_listener_failed", error,
            {licenseId: activation.license.payload.licenseId},
          );
        },
      );
    } catch (error) {
      runtime.applicationLogger.exception(
        "local_runtime.firebase_session_failed", error,
        {licenseId: activation.license.payload.licenseId},
      );
    }
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

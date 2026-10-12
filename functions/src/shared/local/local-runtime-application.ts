import {type LocalMlService} from "../../features/machine_learning/infrastructure/local/local-ml-service.js";
import {type MailConnectorListCache} from "../../features/communication/infrastructure/local/mail-connector-list-cache.js";
import {RuntimeWakeupHandler} from "../../features/communication/infrastructure/local/runtime-wakeup-handler.js";
import {type RuntimeDatabase} from "../../db/database.js";
import {type RuntimeLicenseActivation} from "../../features/licensing/domain/entities/runtime-license-activation.js";
import {type RuntimeLicenseContext} from "../../features/licensing/domain/entities/runtime-license-context.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {createLocalRuntimeComposition, type LocalRuntimeComposition} from "./local-runtime-composition.js";
import {type LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {type LocalRuntimeWorkspaceContext} from "./local-runtime-workspace-context.js";
import {ensureLocalRuntimeWorkspace, type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";

export type LocalRuntimeApplicationOptions = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  realtimeNotifier: LocalRuntimeRealtimeNotifier;
  mailConnectors: MailConnectorListCache;
  isLicenseActive: () => boolean;
  signedLicense: () => SignedRuntimeLicense | null;
  activeLicenseActivation: () => RuntimeLicenseActivation | null;
  mlService: LocalMlService | undefined;
};

/**
 * Lebenszyklus des aktiven Arbeitsbereichs: Worker und team-gebundene
 * Dienste entstehen bei der Lizenzaktivierung und werden bei einem
 * Arbeitsbereichswechsel ersetzt. Die HTTP-Routen bleiben davon unberührt
 * und lesen den aktuellen Stand über `workspaceContext()`.
 */
export class LocalRuntimeApplication {
  private runtime: LocalRuntimeComposition | undefined;
  private workspace: LocalRuntimeWorkspace | undefined;

  constructor(private readonly options: LocalRuntimeApplicationOptions) {}

  async activate(context: RuntimeLicenseContext): Promise<void> {
    const workspace = workspaceFrom(context);
    if (sameWorkspace(this.workspace, workspace)) return;
    await this.stopRuntime();
    this.options.mailConnectors.invalidate();
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

  workspaceContext(): LocalRuntimeWorkspaceContext {
    if (this.runtime === undefined) throw new Error("Der Arbeitsbereich ist nicht aktiviert.");
    return this.runtime.workspaceContext;
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

  private wakeupHandlerFor(runtime: LocalRuntimeComposition, licenseId: string): RuntimeWakeupHandler {
    return new RuntimeWakeupHandler(
      () => void runtime.mailRelayWorker?.processOnce().catch((error) =>
        runtime.applicationLogger.exception(
          "local_runtime.firebase_wakeup_processing_failed", error, {licenseId},
        )),
      this.options.mailConnectors,
      (topic) => this.options.realtimeNotifier.publish(topic),
    );
  }

  private async startFirebaseWakeups(): Promise<void> {
    const runtime = this.runtime;
    const activation = this.options.activeLicenseActivation();
    if (runtime?.firebaseSession === undefined || activation === null) return;
    try {
      await runtime.firebaseSession.start(activation);
      const wakeups = this.wakeupHandlerFor(runtime, activation.license.payload.licenseId);
      runtime.firebaseSession.listenForWakeups(
        activation.license.payload.licenseId,
        (data) => wakeups.handle(data),
        (error) => {
          wakeups.handleFailure();
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

import {err} from "neverthrow";
import {normalizedScriptPackages} from "../../domain/services/script-packages.js";
import {
  type ScriptPackageInstaller,
  type ScriptPackageInstallFailure,
  type ScriptPackageInstallProblem,
} from "../../domain/repositories/script-package-installer.js";
import {type ScriptPackageProbe} from "../../domain/repositories/script-package-probe.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {scriptPackageEnvironmentId} from "./script-package-environment-id.js";

export const scriptPackagesTopic = "script-packages";

export type ScriptPackageEnvironmentStatus = {
  packages: string[];
  state: "installing" | "failed" | "ready";
  reason?: ScriptPackageInstallProblem;
  detail?: string;
  sizeBytes?: number;
};

/** Liefert die normalisierten Paketlisten, die Script-Bausteine noch verwenden. */
export type ScriptPackageUsage = () => Promise<string[][]>;

/**
 * Installiert Paketumgebungen im Hintergrund und prüft danach, ob sie sich im Script-Container
 * laden lassen; eine nicht ladbare Umgebung wird wieder entfernt. Laufende und gescheiterte
 * Installationen stehen im Speicher; fertige kennt der Paketdienst. Änderungen gehen über das
 * Realtime-Thema `script-packages`. Was kein Baustein mehr verwendet, wird entfernt.
 */
export class ScriptPackageJobs {
  private readonly statuses = new Map<string, ScriptPackageEnvironmentStatus>();

  constructor(
    private readonly installer: ScriptPackageInstaller,
    private readonly probe: ScriptPackageProbe,
    private readonly usage: ScriptPackageUsage,
    private readonly notifier: {publish(topic: string): void},
    private readonly logger: ApplicationLogger,
  ) {}

  /** Startet die Installation, falls sie nicht schon läuft; liefert die normalisierte Liste. */
  start(packages: readonly string[]): string[] {
    const normalized = normalizedScriptPackages(packages);
    const id = scriptPackageEnvironmentId(normalized);
    if (this.statuses.get(id)?.state === "installing") return normalized;
    this.update(id, {packages: normalized, state: "installing"});
    void this.install(id, normalized);
    return normalized;
  }

  async list(): Promise<ScriptPackageEnvironmentStatus[]> {
    // Während der Probe liegt die Umgebung schon im Volume, gilt aber noch nicht als fertig.
    const installed = (await this.installer.list())
      .filter((environment) => !this.statuses.has(environment.id))
      .map((environment) => ({packages: environment.packages, state: "ready" as const, sizeBytes: environment.sizeBytes}));
    return [...installed, ...this.statuses.values()];
  }

  /** Entfernt Umgebungen, die kein Script-Baustein mehr verwendet; der Paket-Cache bleibt. */
  async removeUnused(): Promise<void> {
    const used = new Set((await this.usage()).map(scriptPackageEnvironmentId));
    for (const environment of await this.installer.list()) {
      if (used.has(environment.id) || this.statuses.has(environment.id)) continue;
      await this.installer.remove(environment.id);
      this.logger.info("script_packages.removed", {id: environment.id});
    }
    this.notifier.publish(scriptPackagesTopic);
  }

  private async install(id: string, packages: string[]): Promise<void> {
    try {
      const failure = await this.failureOf(id, packages);
      if (failure !== undefined) {
        this.update(id, {packages, state: "failed", ...failure});
        return;
      }
      this.statuses.delete(id);
      this.logger.info("script_packages.installed", {id, packages});
      await this.removeUnused();
    } catch (error: unknown) {
      this.logger.exception("script_packages.install_failed", error, {id});
      this.update(id, {packages, state: "failed", reason: "failed", detail: ""});
    }
  }

  private async failureOf(id: string, packages: string[]): Promise<ScriptPackageInstallFailure | undefined> {
    const installed = await this.installer.install(id, packages);
    if (installed.isErr()) return installed.error;
    const loadable = await this.loadabilityOf(id, packages);
    if (loadable.isOk()) return undefined;
    await this.installer.remove(id);
    this.logger.info("script_packages.not_loadable", {id, detail: loadable.error.detail});
    return loadable.error;
  }

  /** Ohne Antwort des Script-Dienstes gilt die Umgebung als nicht geprüft und damit nicht als fertig. */
  private async loadabilityOf(id: string, packages: string[]) {
    try {
      return await this.probe.check(id, packages);
    } catch (error: unknown) {
      this.logger.exception("script_packages.probe_failed", error, {id});
      return err({reason: "failed" as const, detail: error instanceof Error ? error.message : ""});
    }
  }

  private update(id: string, status: ScriptPackageEnvironmentStatus): void {
    this.statuses.set(id, status);
    this.notifier.publish(scriptPackagesTopic);
  }
}

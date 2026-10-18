import {normalizedScriptPackages} from "../../domain/services/script-packages.js";
import {
  type ScriptPackageInstaller,
  type ScriptPackageInstallProblem,
} from "../../domain/repositories/script-package-installer.js";
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
 * Installiert Paketumgebungen im Hintergrund. Laufende und gescheiterte Installationen
 * stehen im Speicher; fertige kennt der Paketdienst. Änderungen gehen über das
 * Realtime-Thema `script-packages`. Was kein Baustein mehr verwendet, wird entfernt.
 */
export class ScriptPackageJobs {
  private readonly statuses = new Map<string, ScriptPackageEnvironmentStatus>();

  constructor(
    private readonly installer: ScriptPackageInstaller,
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
    const installed = (await this.installer.list()).map((environment) => ({
      packages: environment.packages, state: "ready" as const, sizeBytes: environment.sizeBytes,
    }));
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
      const result = await this.installer.install(id, packages);
      if (result.isErr()) {
        this.update(id, {packages, state: "failed", ...result.error});
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

  private update(id: string, status: ScriptPackageEnvironmentStatus): void {
    this.statuses.set(id, status);
    this.notifier.publish(scriptPackagesTopic);
  }
}

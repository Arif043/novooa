import {type RuntimeDatabase} from "../../../../db/database.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {HttpScriptPackageInstaller} from "./http-script-package-installer.js";
import {HttpScriptPackageProbe} from "./http-script-package-probe.js";
import {ScriptPackageJobs} from "./script-package-jobs.js";
import {sqliteScriptPackageUsage} from "./sqlite-script-package-usage.js";

const cleanupIntervalMs = 24 * 60 * 60 * 1000;

/**
 * Paketumgebungen für Script-Bausteine, wenn Paketdienst (`SCRIPT_PACKAGES_URL`) und Script-Dienst
 * (`SCRIPT_RUNNER_URL`, für die Probe nach der Installation) eingerichtet sind. Räumt einmal
 * täglich ungenutzte Umgebungen ab.
 */
export function scriptPackageJobsFromEnvironment(
  database: RuntimeDatabase,
  notifier: {publish(topic: string): void},
  logger: ApplicationLogger,
): ScriptPackageJobs | undefined {
  const endpoint = process.env.SCRIPT_PACKAGES_URL?.trim();
  const scriptRunner = process.env.SCRIPT_RUNNER_URL?.trim();
  if (!endpoint || !scriptRunner) return undefined;
  const jobs = new ScriptPackageJobs(
    new HttpScriptPackageInstaller(endpoint), new HttpScriptPackageProbe(scriptRunner),
    sqliteScriptPackageUsage(database), notifier, logger,
  );
  setInterval(() => {
    jobs.removeUnused().catch((error: unknown) => logger.exception("script_packages.cleanup_failed", error));
  }, cleanupIntervalMs).unref();
  return jobs;
}

import {type Result} from "neverthrow";

/** Eine fertig installierte Paketumgebung; `packages` ist die normalisierte Liste. */
export type InstalledScriptPackageEnvironment = {id: string; packages: string[]; sizeBytes: number};

/** `notFound`: Paket unbekannt; `noWheel`: kein fertiges Paket für die Plattform; `tooLarge`: über der Obergrenze. */
export type ScriptPackageInstallProblem = "notFound" | "noWheel" | "tooLarge" | "failed";

export type ScriptPackageInstallFailure = {reason: ScriptPackageInstallProblem; detail: string};

/** Baut und entfernt Paketumgebungen für Script-Bausteine (Dienst `novooa-packages`). */
export interface ScriptPackageInstaller {
  list(): Promise<InstalledScriptPackageEnvironment[]>;
  install(id: string, packages: readonly string[]): Promise<Result<InstalledScriptPackageEnvironment, ScriptPackageInstallFailure>>;
  remove(id: string): Promise<void>;
}

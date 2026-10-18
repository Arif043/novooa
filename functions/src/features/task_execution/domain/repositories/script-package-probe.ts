import {type Result} from "neverthrow";
import {type ScriptPackageInstallFailure} from "./script-package-installer.js";

/**
 * Lädt die Pakete einer frisch installierten Umgebung dort, wo Scripts laufen, und unter
 * denselben Grenzen. Installiert heißt nur entpackt; ob eine Bibliothek des Betriebssystems
 * fehlt oder der Import zu lange dauert, zeigt erst diese Probe (`notLoadable`).
 */
export interface ScriptPackageProbe {
  check(id: string, packages: readonly string[]): Promise<Result<void, ScriptPackageInstallFailure>>;
}

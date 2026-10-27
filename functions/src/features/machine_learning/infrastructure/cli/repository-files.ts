import {readdir} from "node:fs/promises";
import path from "node:path";

/** Wurzel des Repos, gerechnet vom übersetzten CLI-Ordner `functions/lib/features/machine_learning/infrastructure/cli`. */
export const repositoryRoot = path.resolve(__dirname, "../../../../../..");

/** Die Python-Skripte der Runtime, die die Prüfungen ausführen. */
export function runtimePythonScript(scriptName: string): string {
  return path.join(repositoryRoot, "local-runtime", "python", scriptName);
}

/** Das gepflegte Tag-Vokabular, Quelle für `models:tags:publish` und `models:install-local`. */
export const shippedModelTagsPath = path.join(repositoryRoot, "models", "tags.json");

/** Alle mitgelieferten Manifeste der Systemmodelle: jede `model.json` unterhalb von `models/`. */
export async function shippedManifestPaths(): Promise<readonly string[]> {
  const catalogModels = path.join(repositoryRoot, "models");
  const files = (await readdir(catalogModels, {recursive: true})).filter((name) => path.basename(name) === "model.json");
  return files.map((name) => path.join(catalogModels, name)).sort();
}

/** Der Journal-Eintrag liegt neben dem Manifest: `models/<modell>/JOURNAL.md`. */
export function journalPathFor(manifestPath: string): string {
  return path.join(path.dirname(manifestPath), "JOURNAL.md");
}

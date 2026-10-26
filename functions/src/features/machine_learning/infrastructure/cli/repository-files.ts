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

/** Alle mitgelieferten Manifeste: Systemmodelle der Runtime und Katalogmodelle unter `models/`. */
export async function shippedManifestPaths(): Promise<readonly string[]> {
  const systemModels = path.join(repositoryRoot, "local-runtime", "system-models");
  const catalogModels = path.join(repositoryRoot, "models");
  const systemFiles = (await readdir(systemModels)).filter((name) => name.endsWith(".json"));
  const catalogFiles = (await readdir(catalogModels, {recursive: true})).filter((name) => path.basename(name) === "model.json");
  return [
    ...systemFiles.map((name) => path.join(systemModels, name)),
    ...catalogFiles.map((name) => path.join(catalogModels, name)),
  ];
}

/** `models/<modell>/model.json` → `JOURNAL.md` daneben; `system-models/<modell>.json` → `<modell>.journal.md`. */
export function journalPathFor(manifestPath: string): string {
  if (path.basename(manifestPath) === "model.json") return path.join(path.dirname(manifestPath), "JOURNAL.md");
  return manifestPath.replace(/\.json$/, ".journal.md");
}

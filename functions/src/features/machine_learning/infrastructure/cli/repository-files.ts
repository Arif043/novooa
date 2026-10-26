import path from "node:path";

/** Wurzel des Repos, gerechnet vom übersetzten CLI-Ordner `functions/lib/features/machine_learning/infrastructure/cli`. */
const repositoryRoot = path.resolve(__dirname, "../../../../../..");

/** Die Python-Skripte der Runtime, die die Prüfungen ausführen. */
export function runtimePythonScript(scriptName: string): string {
  return path.join(repositoryRoot, "local-runtime", "python", scriptName);
}

/** Das gepflegte Tag-Vokabular, Quelle für `models:tags:publish` und `models:install-local`. */
export const shippedModelTagsPath = path.join(repositoryRoot, "models", "tags.json");

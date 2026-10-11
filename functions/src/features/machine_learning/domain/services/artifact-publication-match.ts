import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../repositories/model-artifact-publisher.js";

/** Katalogeintrag und mitgelieferte Dateien müssen dieselbe Modellversion beschreiben. */
export function requirePublicationMatchesEntry(entry: ModelCatalogEntry, artifact: ModelArtifactPublication): void {
  const {resources, externalData, ...reference} = entry.artifactReference;
  const {resources: _resources, externalData: _externalData, ...published} = artifact.reference;
  if (JSON.stringify(reference) !== JSON.stringify(published)) {
    throw new Error("Artefakt und Katalogeintrag referenzieren unterschiedliche Modellversionen.");
  }
  if (!sameFiles(resources ?? [], artifact.resources ?? [])) {
    throw new Error("Die Modellressourcen stimmen nicht mit dem Katalogeintrag überein.");
  }
  if (!sameFiles(externalData ?? [], artifact.externalData ?? [])) {
    throw new Error("Die Gewichtsdateien stimmen nicht mit dem Katalogeintrag überein.");
  }
}

function sameFiles(expected: readonly object[], received: readonly {reference: object}[]): boolean {
  return JSON.stringify(expected) === JSON.stringify(received.map((file) => file.reference));
}

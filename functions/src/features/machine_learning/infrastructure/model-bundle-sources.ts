import {createReadStream} from "node:fs";
import path from "node:path";
import {type Readable} from "node:stream";
import {type ModelCatalogEntry} from "../domain/entities/model-catalog-entry.js";
import {type ModelBundleFile} from "./model-artifact-bundle.js";

/**
 * Woher der ML-Dienst die Dateien eines Modells bekommt: „global“ lädt er selbst aus dem globalen
 * Modellspeicher (bzw. über den Cache des Servers), „team“ schickt ihm die Runtime aus ihrem Speicher.
 */
export type ModelBundleSource = "global" | "team";

export interface ModelBundleSources {
  sourceOf(entry: ModelCatalogEntry): ModelBundleSource;
  teamFileContent(file: ModelBundleFile): Readable;
}

/** Selbst importierte Modelle liegen in der Runtime, alle anderen im globalen Modellspeicher. */
export class RuntimeModelBundleSources implements ModelBundleSources {
  constructor(private readonly runtimeRoot: string) {}

  sourceOf(entry: ModelCatalogEntry): ModelBundleSource {
    return entry.origin === "import" ? "team" : "global";
  }

  teamFileContent(file: ModelBundleFile): Readable {
    return createReadStream(path.join(this.runtimeRoot, file.storePath));
  }
}

/** Alle Modelle kommen aus dem globalen Modellspeicher (Cloud-Inferenzdienst). */
export class GlobalModelBundleSources implements ModelBundleSources {
  sourceOf(): ModelBundleSource {
    return "global";
  }

  teamFileContent(): Readable {
    throw new Error("Dieser Inferenzdienst kennt keine Modelle aus einem Teamspeicher.");
  }
}

/** Alle Modelle liegen in einem lokalen Verzeichnis (Entwicklungsbetrieb des Inferenzdienstes). */
export class LocalDirectoryModelBundleSources extends RuntimeModelBundleSources {
  override sourceOf(): ModelBundleSource {
    return "team";
  }
}

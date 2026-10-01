import {type TransferCategorySelection, type TransferCounts} from "../entities/transfer-category.js";
import {type TransferTeamMapping} from "../entities/transfer-team-mapping.js";
import {type TransferArchiveReader} from "./transfer-archive.js";

export interface TransferImportStore {
  /**
   * Führt die ausgewählten Bereiche atomar zusammen: gleiche IDs werden
   * überschrieben, nichts wird gelöscht. Schlägt ein Bereich fehl, bleibt
   * der Datenbestand unverändert.
   */
  importCategories(input: {
    reader: TransferArchiveReader;
    selection: TransferCategorySelection;
    mapping: TransferTeamMapping;
  }): Promise<TransferCounts>;
}

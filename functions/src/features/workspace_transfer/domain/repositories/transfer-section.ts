import {type TransferCategory} from "../entities/transfer-category.js";
import {type TransferArchiveWriter} from "./transfer-archive.js";

/** Strategie je Bereich: schreibt dessen Bestand ins Archiv und liefert die Anzahl. */
export interface TransferSection {
  readonly category: TransferCategory;
  exportTo(writer: TransferArchiveWriter, teamId: string): Promise<number>;
}

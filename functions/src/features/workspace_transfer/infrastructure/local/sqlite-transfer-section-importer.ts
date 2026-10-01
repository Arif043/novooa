import {type z} from "zod";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {type TransferCategory} from "../../domain/entities/transfer-category.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {transferDataEntry, type TransferArchiveReader} from "../../domain/repositories/transfer-archive.js";

/**
 * Zweiphasig: `stage` liest und prüft das Archiv außerhalb der
 * Datenbank-Transaktion (inkl. Datei-Bytes), `commit` schreibt die Zeilen
 * innerhalb der gemeinsamen Transaktion aller Bereiche.
 */
export interface SqliteTransferSectionImporter {
  readonly category: TransferCategory;
  stage(reader: TransferArchiveReader, mapping: TransferTeamMapping): Promise<StagedSectionImport>;
}

export type StagedSectionImport = {
  count: number;
  commit(executor: RuntimeExecutor): Promise<void>;
  /** Entfernt beim Staging angelegte Dateien, falls der Import scheitert. */
  rollback(): Promise<void>;
};

export async function sectionPayload<T>(
  reader: TransferArchiveReader,
  name: string,
  schema: z.ZodType<T>,
): Promise<T> {
  const parsed = schema.safeParse(await reader.json(transferDataEntry(name)));
  if (parsed.success) return parsed.data;
  throw new InvalidTransferArchiveError(`Der Bereich „${name}“ im Export ist unvollständig oder ungültig.`);
}

export function stagedRows(count: number, commit: StagedSectionImport["commit"]): StagedSectionImport {
  return {count, commit, rollback: async () => undefined};
}

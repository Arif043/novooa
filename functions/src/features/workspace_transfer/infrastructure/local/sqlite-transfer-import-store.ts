import {type RuntimeDatabase} from "../../../../db/database.js";
import {type TransferCategory, type TransferCategorySelection, type TransferCounts} from "../../domain/entities/transfer-category.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {type TransferArchiveReader} from "../../domain/repositories/transfer-archive.js";
import {type TransferImportStore} from "../../domain/repositories/transfer-import-store.js";
import {type SqliteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

type StagedCategory = {category: TransferCategory; staged: StagedSectionImport};

export class SqliteTransferImportStore implements TransferImportStore {
  constructor(
    private readonly database: RuntimeDatabase,
    private readonly importers: readonly SqliteTransferSectionImporter[],
  ) {}

  async importCategories(input: {
    reader: TransferArchiveReader; selection: TransferCategorySelection; mapping: TransferTeamMapping;
  }): Promise<TransferCounts> {
    const stagedCategories = await this.stageAll(input);
    try {
      await this.database.transaction(async (transaction) => {
        for (const {staged} of stagedCategories) await staged.commit(transaction);
      });
    } catch (error) {
      await rollbackAll(stagedCategories);
      throw error;
    }
    return Object.fromEntries(stagedCategories.map(({category, staged}) => [category, staged.count]));
  }

  private async stageAll(input: {
    reader: TransferArchiveReader; selection: TransferCategorySelection; mapping: TransferTeamMapping;
  }): Promise<StagedCategory[]> {
    const stagedCategories: StagedCategory[] = [];
    try {
      for (const category of input.selection.categories) {
        const staged = await this.importerFor(category).stage(input.reader, input.mapping);
        stagedCategories.push({category, staged});
      }
      return stagedCategories;
    } catch (error) {
      await rollbackAll(stagedCategories);
      throw error;
    }
  }

  private importerFor(category: TransferCategory): SqliteTransferSectionImporter {
    const importer = this.importers.find((candidate) => candidate.category === category);
    if (importer === undefined) throw new Error(`Kein Import für Bereich ${category} registriert.`);
    return importer;
  }
}

async function rollbackAll(stagedCategories: readonly StagedCategory[]): Promise<void> {
  for (const {staged} of stagedCategories) await staged.rollback();
}

import {type TransferCategorySelection, type TransferCounts} from "../entities/transfer-category.js";
import {TransferTeamMapping} from "../entities/transfer-team-mapping.js";
import {type TransferArchiveReader} from "../repositories/transfer-archive.js";
import {type TransferImportStore} from "../repositories/transfer-import-store.js";
import {type InspectWorkspaceImport} from "./inspect-workspace-import.js";

export class ImportWorkspace {
  constructor(
    private readonly inspect: InspectWorkspaceImport,
    private readonly store: TransferImportStore,
  ) {}

  async execute(input: {
    teamId: string; selection: TransferCategorySelection; reader: TransferArchiveReader;
  }): Promise<TransferCounts> {
    const manifest = await this.inspect.execute(input.reader);
    return this.store.importCategories({
      reader: input.reader,
      selection: input.selection.restrictedTo(manifest.categories),
      mapping: new TransferTeamMapping(manifest.sourceTeamId, input.teamId),
    });
  }
}

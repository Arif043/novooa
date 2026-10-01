import {type TransferCategorySelection, type TransferCounts} from "../entities/transfer-category.js";
import {createTransferManifest, transferManifestEntry, type TransferManifest} from "../entities/transfer-manifest.js";
import {type TransferArchiveWriter} from "../repositories/transfer-archive.js";
import {type TransferSection} from "../repositories/transfer-section.js";

export class ExportWorkspace {
  constructor(
    private readonly sections: readonly TransferSection[],
    private readonly now: () => Date = () => new Date(),
  ) {}

  async execute(input: {
    teamId: string; selection: TransferCategorySelection; writer: TransferArchiveWriter;
  }): Promise<TransferManifest> {
    const counts: TransferCounts = {};
    for (const category of input.selection.categories) {
      counts[category] = await this.sectionFor(category).exportTo(input.writer, input.teamId);
    }
    const manifest = createTransferManifest({sourceTeamId: input.teamId, counts, exportedAt: this.now()});
    await input.writer.addJson(transferManifestEntry, manifest);
    return manifest;
  }

  private sectionFor(category: string): TransferSection {
    const section = this.sections.find((candidate) => candidate.category === category);
    if (section === undefined) throw new Error(`Kein Export für Bereich ${category} registriert.`);
    return section;
  }
}

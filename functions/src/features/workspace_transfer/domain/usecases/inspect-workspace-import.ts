import {transferManifestEntry, transferManifestFrom, type TransferManifest} from "../entities/transfer-manifest.js";
import {type TransferArchiveReader} from "../repositories/transfer-archive.js";

export class InspectWorkspaceImport {
  async execute(reader: TransferArchiveReader): Promise<TransferManifest> {
    return transferManifestFrom(await reader.json(transferManifestEntry));
  }
}

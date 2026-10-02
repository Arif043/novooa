import {type NodeAttachment} from "../entities/attachments.js";
import {
  type StoredTeamFile,
  type TeamFileStore,
  type WriteTeamFileInput,
  type WrittenFile,
} from "../../../files/domain/repositories/team-file-store.js";

/**
 * Markiert jede Schreiboperation eines Laufs mit dessen Ursachenkette
 * (Decorator). Alle Executoren schreiben so automatisch richtig, ohne die
 * Kette selbst zu kennen.
 */
export class TriggerChainTeamFileStore implements TeamFileStore {
  constructor(
    private readonly inner: TeamFileStore,
    private readonly triggerChain: readonly string[],
  ) {}

  writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile> {
    if (this.triggerChain.length === 0) return this.inner.writeTeamFile(input);
    return this.inner.writeTeamFile({...input, triggerChain: this.triggerChain});
  }

  loadTeamFile(teamId: string, fileId: string): Promise<StoredTeamFile> {
    return this.inner.loadTeamFile(teamId, fileId);
  }

  readTextFile(teamId: string, file: NodeAttachment): Promise<string> {
    return this.inner.readTextFile(teamId, file);
  }
}

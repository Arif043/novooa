import {type FileEvent} from "../../../files/domain/entities/file-event.js";
import {type FileEventPublisher} from "../../../files/domain/repositories/file-event-publisher.js";
import {type FolderAncestry} from "../../../files/domain/repositories/folder-ancestry.js";
import {type EventTaskTrigger} from "../repositories/task-trigger-store.js";
import {fileEventMatches} from "./event-trigger-matching.js";
import {startEventTriggerRun, type EventTriggerRunPorts} from "./start-event-trigger-run.js";

const eventLabels = {
  fileCreated: "Datei erstellt",
  fileVersionCreated: "Neue Dateiversion",
  fileDeleted: "Datei gelöscht",
} as const;

export type FileEventDispatcherPorts = EventTriggerRunPorts & {
  folders: FolderAncestry;
  /** Ein fehlgeschlagener Trigger darf weder die Dateioperation noch andere Trigger stoppen. */
  onFailure?: (error: unknown, trigger?: EventTaskTrigger) => void;
  /** Der Trigger steht schon in der Ursachenkette des Ereignisses: Er würde einen Zyklus schließen. */
  onLoopPrevented?: (trigger: EventTaskTrigger, event: FileEvent) => void;
};

/** Startet alle aktiven Event-Trigger, die zu einem Datei-Ereignis passen. */
export class DispatchFileEvent implements FileEventPublisher {
  constructor(private readonly ports: FileEventDispatcherPorts) {}

  async publish(event: FileEvent): Promise<void> {
    try {
      const triggers = await this.ports.triggerStore.listEnabledEventTriggers(event.teamId);
      const candidates = triggers.filter(
        (trigger) => trigger.type === "event" && trigger.eventConfig.source === event.type,
      );
      if (candidates.length === 0) return;
      const folderChain = await this.folderChainOf(event);
      for (const trigger of candidates) await this.dispatch(trigger, event, folderChain);
    } catch (error) {
      this.ports.onFailure?.(error);
    }
  }

  private async folderChainOf(event: FileEvent): Promise<string[]> {
    if (event.folderId === null) return [];
    return this.ports.folders.chainOf(event.teamId, event.folderId);
  }

  private async dispatch(trigger: EventTaskTrigger, event: FileEvent, folderChain: string[]): Promise<void> {
    if (!fileEventMatches(trigger.eventConfig, event, folderChain)) return;
    if (event.triggerChain.includes(trigger.id)) {
      this.ports.onLoopPrevented?.(trigger, event);
      return;
    }
    try {
      await startEventTriggerRun(
        trigger, {context: contextFrom(event), event, chain: event.triggerChain}, this.ports,
      );
    } catch (error) {
      this.ports.onFailure?.(error, trigger);
    }
  }
}

function contextFrom(event: FileEvent): string {
  return [eventLabels[event.type], `Datei: ${event.displayName}`, `Typ: ${event.contentType}`].join("\n");
}

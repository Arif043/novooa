import {type FileEvent} from "../entities/file-event.js";

/** Meldet Datei-Ereignisse an interessierte Abnehmer (z. B. Event-Trigger). */
export interface FileEventPublisher {
  publish(event: FileEvent): Promise<void>;
}

export const noFileEventPublisher: FileEventPublisher = {
  async publish() {},
};

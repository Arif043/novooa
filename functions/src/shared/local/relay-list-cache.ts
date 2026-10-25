import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";

/**
 * Hält eine Liste aus einem Relay (Postfächer, Google-Konten), solange Firebase kein neues Ereignis meldet.
 * Firebase bleibt die Quelle der Wahrheit: Der Cache wird nie nach Zeit verworfen, sondern geleert, wenn ein
 * Wake-up eine Änderung meldet ([invalidate]) — oder wenn die Verbindung abreißt und Ereignisse fehlen könnten.
 */
export class RelayListCache<T> {
  private entry: {licenseId: string; items: Promise<T[]>} | undefined;

  list(license: SignedRuntimeLicense, load: () => Promise<T[]>): Promise<T[]> {
    const licenseId = license.payload.licenseId;
    if (this.entry?.licenseId === licenseId) return this.entry.items;
    const entry = {licenseId, items: load()};
    this.entry = entry;
    // Ein Fehlschlag wird nicht festgehalten, sonst bliebe er bis zum nächsten Ereignis.
    entry.items.catch(() => {
      if (this.entry === entry) this.entry = undefined;
    });
    return entry.items;
  }

  invalidate(): void {
    this.entry = undefined;
  }
}

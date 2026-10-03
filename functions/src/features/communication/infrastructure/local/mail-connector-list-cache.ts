import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type MailConnectorSummary} from "../../domain/entities/mail-connector-summary.js";

/**
 * Hält die Postfachliste aus der Cloud, solange die Cloud kein neues Ereignis
 * meldet. Die Cloud bleibt die Quelle der Wahrheit: Der Cache wird nie nach
 * Zeit verworfen, sondern geleert, wenn sie ein Ereignis feuert
 * ([invalidate]) — oder wenn die Verbindung zu ihr abreißt und Ereignisse
 * verpasst worden sein könnten.
 */
export class MailConnectorListCache {
  private entry: {licenseId: string; connectors: Promise<MailConnectorSummary[]>} | undefined;

  list(
    license: SignedRuntimeLicense,
    load: () => Promise<MailConnectorSummary[]>,
  ): Promise<MailConnectorSummary[]> {
    const licenseId = license.payload.licenseId;
    if (this.entry?.licenseId === licenseId) return this.entry.connectors;
    const entry = {licenseId, connectors: load()};
    this.entry = entry;
    // Ein Fehlschlag wird nicht festgehalten, sonst bliebe er bis zum nächsten Ereignis.
    entry.connectors.catch(() => {
      if (this.entry === entry) this.entry = undefined;
    });
    return entry.connectors;
  }

  invalidate(): void {
    this.entry = undefined;
  }
}

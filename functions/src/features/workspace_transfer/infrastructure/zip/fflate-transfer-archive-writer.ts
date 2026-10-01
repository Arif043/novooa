import {strToU8, Zip, ZipDeflate} from "fflate";
import {PassThrough} from "node:stream";
import {type TransferArchiveWriter} from "../../domain/repositories/transfer-archive.js";

/**
 * Schreibt das Archiv als Stream, damit große Datei-Bestände nicht im
 * Speicher der Runtime landen. `output` wird direkt als HTTP-Antwort gesendet.
 */
export class FflateTransferArchiveWriter implements TransferArchiveWriter {
  readonly output = new PassThrough();
  private readonly zip = new Zip((error, chunk, final) => this.forward(error, chunk, final));

  async addJson(name: string, value: unknown): Promise<void> {
    const entry = new ZipDeflate(name, {level: 6});
    this.zip.add(entry);
    entry.push(strToU8(JSON.stringify(value)), true);
    await this.drained();
  }

  async addBlob(name: string, content: AsyncIterable<Uint8Array>): Promise<void> {
    const entry = new ZipDeflate(name, {level: 1});
    this.zip.add(entry);
    for await (const chunk of content) {
      entry.push(chunk);
      await this.drained();
    }
    entry.push(new Uint8Array(0), true);
    await this.drained();
  }

  finish(): void {
    this.zip.end();
  }

  fail(error: unknown): void {
    this.zip.terminate();
    this.output.destroy(error instanceof Error ? error : new Error(String(error)));
  }

  private forward(error: Error | null, chunk: Uint8Array, final: boolean): void {
    if (error !== null) {
      this.output.destroy(error);
      return;
    }
    this.output.write(chunk);
    if (final) this.output.end();
  }

  private async drained(): Promise<void> {
    if (this.output.destroyed) throw new Error("Der Export wurde abgebrochen.");
    if (!this.output.writableNeedDrain) return;
    await new Promise<void>((resolve, reject) => {
      const onDrain = () => settle(resolve);
      const onClose = () => settle(() => reject(new Error("Der Export wurde abgebrochen.")));
      const settle = (next: () => void) => {
        this.output.off("drain", onDrain).off("close", onClose);
        next();
      };
      this.output.once("drain", onDrain).once("close", onClose);
    });
  }
}

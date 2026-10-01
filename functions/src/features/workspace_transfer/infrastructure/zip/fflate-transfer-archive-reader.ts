import {strFromU8, Unzip, UnzipInflate, type UnzipFile} from "fflate";
import {createReadStream} from "node:fs";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {type TransferArchiveReader} from "../../domain/repositories/transfer-archive.js";

type CompletedEntry = {name: string; content: Uint8Array};
type EntryConsumer = (name: string, content: Uint8Array) => Promise<void>;

const maximumJsonBytes = 256 * 1024 * 1024;
const maximumBlobBytes = 2 * 1024 * 1024 * 1024;

/**
 * Liest ein gestagtes Archiv sequentiell. JSON-Einträge werden einmal
 * gesammelt; Blobs werden in einem zweiten Durchlauf einzeln weitergereicht,
 * damit nie das ganze Archiv im Speicher liegt.
 */
export class FflateTransferArchiveReader implements TransferArchiveReader {
  private jsonEntries: Promise<Map<string, unknown>> | undefined;

  constructor(private readonly archivePath: string) {}

  async json(name: string): Promise<unknown> {
    this.jsonEntries ??= this.loadJsonEntries();
    return (await this.jsonEntries).get(name);
  }

  async forEachBlob(names: ReadonlySet<string>, consumer: EntryConsumer): Promise<void> {
    await this.scan((name) => names.has(name), maximumBlobBytes, consumer);
  }

  private async loadJsonEntries(): Promise<Map<string, unknown>> {
    const entries = new Map<string, unknown>();
    await this.scan(isJsonEntry, maximumJsonBytes, async (name, content) => {
      entries.set(name, parsedJson(content));
    });
    return entries;
  }

  private async scan(accept: (name: string) => boolean, limit: number, consumer: EntryConsumer): Promise<void> {
    const pending = new PendingEntries();
    const unzip = new Unzip((file) => {
      if (accept(file.name)) collect(file, limit, pending);
    });
    unzip.register(UnzipInflate);
    for await (const chunk of createReadStream(this.archivePath)) {
      pushChunk(unzip, chunk as Buffer, false);
      await pending.drainInto(consumer);
    }
    pushChunk(unzip, new Uint8Array(0), true);
    await pending.drainInto(consumer);
  }
}

class PendingEntries {
  readonly completed: CompletedEntry[] = [];
  failure: unknown;

  async drainInto(consumer: EntryConsumer): Promise<void> {
    if (this.failure !== undefined) throw this.failure;
    while (this.completed.length > 0) {
      const entry = this.completed.shift() as CompletedEntry;
      await consumer(entry.name, entry.content);
    }
  }
}

function collect(file: UnzipFile, limit: number, pending: PendingEntries): void {
  const chunks: Uint8Array[] = [];
  let size = 0;
  file.ondata = (error, chunk, final) => {
    if (error !== null) return void (pending.failure = invalidArchive());
    size += chunk.length;
    if (size > limit) {
      pending.failure = new InvalidTransferArchiveError("Ein Eintrag im Export ist zu groß.");
      return file.terminate();
    }
    chunks.push(chunk);
    if (final) pending.completed.push({name: file.name, content: Buffer.concat(chunks)});
  };
  file.start();
}

function pushChunk(unzip: Unzip, chunk: Uint8Array, final: boolean): void {
  try {
    unzip.push(chunk, final);
  } catch {
    throw invalidArchive();
  }
}

function isJsonEntry(name: string): boolean {
  return name.endsWith(".json") && !name.startsWith("blobs/");
}

function parsedJson(content: Uint8Array): unknown {
  try {
    return JSON.parse(strFromU8(content));
  } catch {
    throw new InvalidTransferArchiveError("Der Export enthält ungültige Daten.");
  }
}

function invalidArchive(): InvalidTransferArchiveError {
  return new InvalidTransferArchiveError("Die Datei ist kein gültiges ZIP-Archiv.");
}

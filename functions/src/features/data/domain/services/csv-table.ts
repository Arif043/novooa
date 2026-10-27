/** Eine CSV-Zeile mit der Zeilennummer, in der sie in der Datei beginnt (für Fehlermeldungen). */
export type CsvRecord = {line: number; cells: string[]};

const byteOrderMark = "﻿";

/**
 * Liest CSV nach RFC 4180 (Anführungszeichen, verdoppelte Anführungszeichen, Zeilenumbrüche in
 * Zellen, CRLF oder LF). Trennzeichen Komma oder Semikolon — Excel speichert im deutschen
 * Gebietsschema mit Semikolon; entschieden wird an der ersten Zeile.
 */
export function parseCsv(content: string): CsvRecord[] {
  const text = content.startsWith(byteOrderMark) ? content.slice(1) : content;
  const reader = new CsvReader(text, delimiterOf(text));
  return reader.records().filter((record) => !(record.cells.length === 1 && record.cells[0] === ""));
}

/** Schreibt CSV mit Komma, CRLF und BOM, damit Excel UTF-8 erkennt. */
export function writeCsv(header: readonly string[], rows: readonly (readonly string[])[]): string {
  const lines = [header, ...rows].map((cells) => cells.map(quoted).join(","));
  return byteOrderMark + lines.join("\r\n") + "\r\n";
}

function quoted(cell: string): string {
  return /[",\r\n;]/.test(cell) || cell !== cell.trim() ? `"${cell.replace(/"/g, "\"\"")}"` : cell;
}

function delimiterOf(text: string): string {
  let commas = 0;
  let semicolons = 0;
  let inQuotes = false;
  for (const character of text) {
    if (character === "\"") inQuotes = !inQuotes;
    else if (!inQuotes && (character === "\n" || character === "\r")) break;
    else if (!inQuotes && character === ",") commas += 1;
    else if (!inQuotes && character === ";") semicolons += 1;
  }
  return semicolons > commas ? ";" : ",";
}

class CsvReader {
  private position = 0;
  private line = 1;

  constructor(private readonly text: string, private readonly delimiter: string) {}

  records(): CsvRecord[] {
    const records: CsvRecord[] = [];
    while (this.position < this.text.length) records.push(this.record());
    return records;
  }

  private record(): CsvRecord {
    const line = this.line;
    const cells = [this.cell()];
    while (this.position < this.text.length && this.text[this.position] === this.delimiter) {
      this.position += 1;
      cells.push(this.cell());
    }
    this.endOfRecord();
    return {line, cells};
  }

  private cell(): string {
    if (this.text[this.position] !== "\"") return this.plainCell();
    this.position += 1;
    let value = "";
    while (this.position < this.text.length) {
      const character = this.text[this.position];
      if (character === "\"" && this.text[this.position + 1] === "\"") {
        value += "\"";
        this.position += 2;
      } else if (character === "\"") {
        this.position += 1;
        return value + this.plainCell();
      } else {
        if (character === "\n") this.line += 1;
        value += character;
        this.position += 1;
      }
    }
    throw new Error(`Zeile ${this.line}: Ein Anführungszeichen wird nicht geschlossen.`);
  }

  private plainCell(): string {
    const start = this.position;
    while (this.position < this.text.length && !this.isCellEnd(this.text[this.position])) this.position += 1;
    return this.text.slice(start, this.position);
  }

  private isCellEnd(character: string): boolean {
    return character === this.delimiter || character === "\n" || character === "\r";
  }

  private endOfRecord(): void {
    if (this.text[this.position] === "\r") this.position += 1;
    if (this.text[this.position] === "\n") this.position += 1;
    this.line += 1;
  }
}

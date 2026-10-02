import {type FileContentKind} from "../../../files/domain/entities/file-content-kind.js";

/**
 * Eine Stelle in einer Aufgabe, an der sie Dateien schreiben kann — das, was
 * die statische Schleifenanalyse von der Aufgabe sehen muss.
 */
export type FileWriteSite = {
  /**
   * `folder`: legt eine neue Datei an einem bekannten Ort an (`null` = oberste
   * Ebene). `existingFile`: schreibt eine neue Version einer bekannten Datei;
   * deren Verzeichnis ist zur Entwurfszeit nicht bekannt.
   */
  placement:
    | {kind: "folder"; folderId: string | null}
    | {kind: "existingFile"; fileId: string};
  /** `null` = unbekannt; ein Name mit `{{` ist ein Template. */
  fileName: string | null;
  /** `null` = unbekannt. */
  contentKind: FileContentKind | null;
  /**
   * Ob [contentKind] verlässlich ist. Beim Baustein „Datei schreiben" kann der
   * Quellwert den Typ zur Laufzeit ändern (Bild, Tabelle).
   */
  contentKindIsCertain: boolean;
};

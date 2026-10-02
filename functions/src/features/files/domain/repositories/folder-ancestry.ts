/** Beantwortet, in welchen Verzeichnissen ein Verzeichnis liegt. */
export interface FolderAncestry {
  /** Das Verzeichnis selbst und alle Eltern bis zur Wurzel, nächstes zuerst. */
  chainOf(teamId: string, folderId: string): Promise<string[]>;

  /** Alle Verzeichnisse des Teams mit ihrem Elternverzeichnis (`null` = oberste Ebene). */
  parentsOf(teamId: string): Promise<ReadonlyMap<string, string | null>>;
}

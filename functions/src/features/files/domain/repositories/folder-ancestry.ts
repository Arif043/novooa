/** Beantwortet, in welchen Verzeichnissen ein Verzeichnis liegt. */
export interface FolderAncestry {
  /** Das Verzeichnis selbst und alle Eltern bis zur Wurzel, nächstes zuerst. */
  chainOf(teamId: string, folderId: string): Promise<string[]>;
}

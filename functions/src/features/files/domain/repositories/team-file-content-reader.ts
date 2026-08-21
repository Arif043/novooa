export type TeamFileContent = {
  content: Uint8Array;
  displayName: string;
  contentType: string;
  sizeBytes: number;
};

export interface TeamFileContentReader {
  readTeamFileContent(
    teamId: string,
    fileId: string,
    versionId: string,
  ): Promise<TeamFileContent>;
}

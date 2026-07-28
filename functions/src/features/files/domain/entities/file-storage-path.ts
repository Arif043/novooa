export function storagePathFor(
  teamId: string,
  fileId: string,
  versionId: string,
  fileName: string,
): string {
  return `teams/${teamId}/files/${fileId}/versions/${versionId}/${fileName}`;
}

export interface TeamContextStore {
  currentTeamIdForUid(uid: string): Promise<string>;
}

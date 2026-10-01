export interface FileSettingsStore {
  loadVersionLimit(teamId: string): Promise<number>;
  saveVersionLimit(teamId: string, limit: number): Promise<void>;
}

/** Sitzungen eines Kontos beginnen und beenden (samt offener Realtime-Verbindungen). */
export interface RuntimeSessionAccess {
  createSession(uid: string): Promise<string>;
  revokeSessionsOf(uid: string): Promise<void>;
}

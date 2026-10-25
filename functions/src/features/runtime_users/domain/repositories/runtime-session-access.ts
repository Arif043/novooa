import {type SessionDevice} from "../entities/session-device.js";

/** Sitzungen eines Kontos beginnen und beenden (samt offener Realtime-Verbindungen). */
export interface RuntimeSessionAccess {
  createSession(uid: string, device: SessionDevice): Promise<string>;
  revokeSessionsOf(uid: string): Promise<void>;
}

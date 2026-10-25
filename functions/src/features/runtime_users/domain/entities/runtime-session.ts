import {type SessionDevice} from "./session-device.js";

/** Eine angemeldete Sitzung, wie ihr Konto sie sieht; `current` ist die Sitzung der Anfrage. */
export type RuntimeSessionSummary = {
  id: string;
  current: boolean;
  createdAt: string;
  lastUsedAt: string;
  device: Pick<SessionDevice, "app" | "os" | "browser">;
};

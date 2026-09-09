import {type LogData} from "./application-logger.js";

export type ApplicationLogLevel = "info" | "error";
export type ApplicationLogSource = "client" | "runtime";

export type LocalApplicationLog = {
  id: string;
  teamId: string;
  level: ApplicationLogLevel;
  source: ApplicationLogSource;
  event: string;
  message: string | null;
  data: LogData;
  occurredAt: string;
};

export interface LocalApplicationLogStore {
  append(log: LocalApplicationLog): Promise<void>;
  recent(teamId: string, limit: number): Promise<LocalApplicationLog[]>;
}

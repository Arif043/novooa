/** Der zuletzt gemeldete Zustand je Trigger (z. B. ein Cursor), damit Ereignisse nicht doppelt auslösen. */
export interface PluginTriggerStateStore {
  read(triggerId: string): Promise<unknown>;
  write(triggerId: string, state: unknown): Promise<void>;
  delete(triggerId: string): Promise<void>;
}

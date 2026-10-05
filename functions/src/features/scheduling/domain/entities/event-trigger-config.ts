import {
  fileContentKinds,
  type FileContentKind,
} from "../../../files/domain/entities/file-content-kind.js";

export const eventTriggerSources = [
  "emailReceived",
  "smsMessageReceived",
  "whatsappMessageReceived",
  "fileCreated",
  "fileVersionCreated",
  "fileDeleted",
  "webhookReceived",
  /** Ereignisse, die ein installiertes Plugin liefert (siehe `eventConfig.plugin`). */
  "plugin",
] as const;

/**
 * Worauf sich ein Event-Trigger bezieht. Dieselbe Struktur gilt für alle
 * Quellen: Dateien zielen auf Verzeichnis oder Datei, Nachrichten auf einen
 * Kanal bzw. Mail-Connector, `any` heißt „überall".
 */
export type EventTriggerTarget =
  | {kind: "any"}
  | {kind: "folder"; id: string; label: string; includeSubfolders: boolean}
  | {kind: "file"; id: string; label: string}
  | {kind: "channel"; id: string; label: string}
  | {kind: "connector"; id: string; label: string};

/** Welcher Trigger eines Plugins mit welchen Einstellungen gemeint ist. */
export type PluginTriggerReference = {
  pluginId: string;
  type: string;
  settings: Record<string, string | number | boolean>;
};

export type EventTriggerConfig = {
  source: string;
  target: EventTriggerTarget;
  fileKinds: FileContentKind[];
  filter: string;
  plugin?: PluginTriggerReference;
};

export function eventTriggerConfigFrom(value: unknown): EventTriggerConfig {
  const data = isRecord(value) ? value : {};
  const plugin = pluginReferenceFrom(data.plugin);
  return {
    source: stringOr(data.source, ""),
    target: eventTriggerTargetFrom(data.target),
    fileKinds: fileKindsFrom(data.fileKinds),
    filter: stringOr(data.filter, ""),
    ...(plugin === undefined ? {} : {plugin}),
  };
}

export function pluginReferenceFrom(value: unknown): PluginTriggerReference | undefined {
  if (!isRecord(value)) return undefined;
  const pluginId = stringOr(value.pluginId, "").trim();
  const type = stringOr(value.type, "").trim();
  if (pluginId.length === 0 || type.length === 0) return undefined;
  const settings: PluginTriggerReference["settings"] = {};
  if (isRecord(value.settings)) {
    for (const [key, setting] of Object.entries(value.settings)) {
      if (typeof setting === "string" || typeof setting === "number" || typeof setting === "boolean") settings[key] = setting;
    }
  }
  return {pluginId, type, settings};
}

export function eventTriggerTargetFrom(value: unknown): EventTriggerTarget {
  const data = isRecord(value) ? value : {};
  const id = stringOr(data.id, "").trim();
  if (id.length === 0) return {kind: "any"};
  // `label` ist nur ein Anzeigename für die Trigger-Karte, nie Teil des Matchings.
  const label = stringOr(data.label, "").trim().slice(0, 200);
  switch (data.kind) {
    case "folder": return {kind: "folder", id, label, includeSubfolders: data.includeSubfolders !== false};
    case "file": return {kind: "file", id, label};
    case "channel": return {kind: "channel", id, label};
    case "connector": return {kind: "connector", id, label};
    default: return {kind: "any"};
  }
}

export function isEventTriggerSource(value: unknown): boolean {
  return typeof value === "string" && (eventTriggerSources as readonly string[]).includes(value);
}

function fileKindsFrom(value: unknown): FileContentKind[] {
  if (!Array.isArray(value)) return [];
  const known = new Set<string>(fileContentKinds);
  return value.filter((kind): kind is FileContentKind => typeof kind === "string" && known.has(kind));
}

function stringOr(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

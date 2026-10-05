import {z} from "genkit";
import {PluginPackageError} from "./plugin-package-error.js";

export const pluginFieldKinds = ["text", "multilineText", "number", "choice", "toggle", "template"] as const;
export const pluginOutputTypes = ["string", "number", "boolean", "datetime", "json"] as const;

const identifier = z.string().regex(/^[a-z][a-zA-Z0-9]{0,39}$/, "Erlaubt sind Buchstaben und Ziffern, beginnend mit einem Kleinbuchstaben.");
const label = z.string().trim().min(1).max(80);
const description = z.string().trim().max(300);

const field = z.object({
  key: identifier,
  label,
  kind: z.enum(pluginFieldKinds),
  description: description.optional(),
  required: z.boolean().default(false),
  /** Nur für Einstellungs-Panels: Wert bleibt im Backend und wird nie an den Client zurückgegeben. */
  secret: z.boolean().default(false),
  options: z.array(z.object({value: z.string().min(1).max(80), label})).max(50).optional(),
  defaultValue: z.union([z.string().max(2000), z.number(), z.boolean()]).optional(),
}).superRefine((value, context) => {
  if (value.kind === "choice" && (value.options === undefined || value.options.length === 0)) {
    context.addIssue({code: "custom", message: `Das Auswahlfeld „${value.key}“ braucht options.`});
  }
});

const fields = z.array(field).max(30).default([]);

const primitive = z.object({
  type: identifier,
  label,
  description,
  group: label.optional(),
  icon: z.string().trim().max(40).optional(),
  settings: fields,
  outputs: z.array(z.object({name: identifier, label, type: z.enum(pluginOutputTypes)})).max(20).default([]),
});

const trigger = z.object({type: identifier, label, description, settings: fields});

const settingsPanel = z.object({id: identifier, title: label, description: description.optional(), icon: z.string().trim().max(40).optional(), fields});

const manifestSchema = z.object({
  schemaVersion: z.literal(1),
  id: z.string().regex(/^[a-z][a-z0-9-]{1,39}$/, "Die Plugin-ID besteht aus Kleinbuchstaben, Ziffern und Bindestrichen."),
  version: z.string().regex(/^\d+\.\d+\.\d+$/, "Die Version hat die Form 1.2.3."),
  name: label,
  description,
  minAppVersion: z.string().regex(/^\d+\.\d+\.\d+$/).optional(),
  entry: z.string().min(1).max(200).default("backend/index.mjs"),
  /** Hostnamen, die das Plugin per Netzwerk erreichen darf. Leer = kein Netzzugriff. */
  network: z.array(z.string().regex(/^[a-z0-9.-]+$/)).max(10).default([]),
  primitives: z.array(primitive).max(50).default([]),
  triggers: z.array(trigger).max(20).default([]),
  settingsPanels: z.array(settingsPanel).max(10).default([]),
}).superRefine((manifest, context) => {
  const duplicates = (kind: string, values: string[]) => {
    const seen = new Set<string>();
    for (const value of values) {
      if (seen.has(value)) context.addIssue({code: "custom", message: `${kind} „${value}“ kommt doppelt vor.`});
      seen.add(value);
    }
  };
  duplicates("Baustein", manifest.primitives.map((item) => item.type));
  duplicates("Trigger", manifest.triggers.map((item) => item.type));
  duplicates("Panel", manifest.settingsPanels.map((item) => item.id));
});

export type PluginManifest = z.infer<typeof manifestSchema>;
export type PluginField = z.infer<typeof field>;
export type PluginPrimitiveDefinition = PluginManifest["primitives"][number];
export type PluginTriggerDefinition = PluginManifest["triggers"][number];

export function parsePluginManifest(text: string): PluginManifest {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new PluginPackageError("Die plugin.json ist kein gültiges JSON.");
  }
  const parsed = manifestSchema.safeParse(raw);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    throw new PluginPackageError(`Die plugin.json ist ungültig (${issue?.path.join(".") || "Wurzel"}): ${issue?.message ?? "unbekannter Fehler"}`);
  }
  return parsed.data;
}

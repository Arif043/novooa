import {z} from "genkit";
import {type NestedRun} from "../../../domain/entities/nested-run.js";

const effectBase = {sourceNodeId: z.string(), iteration: z.number().int().nonnegative().optional()};

/**
 * Effekte im Journal und im Resume-Zustand; ohne dieses Schema gingen sie beim Fortsetzen
 * eines Laufs verloren. Unbekannte Arten (neuere Runtime) werden verworfen statt abgelehnt.
 */
export const runEffectSchema = z.discriminatedUnion("kind", [
  z.object({
    ...effectBase, kind: z.literal("fileWritten"), fileId: z.string(), versionId: z.string(), displayName: z.string(),
    contentType: z.string(), sizeBytes: z.number(), isNewFile: z.boolean(),
  }),
  z.object({
    ...effectBase, kind: z.literal("messageSent"), channel: z.enum(["email", "whatsapp", "sms"]),
    recipient: z.string(), subject: z.string().optional(),
  }),
  z.object({...effectBase, kind: z.literal("notificationSent"), title: z.string()}),
  z.object({
    ...effectBase, kind: z.literal("recordsChanged"), collectionId: z.string(),
    operation: z.enum(["created", "updated", "deleted"]), documentId: z.string().optional(), count: z.number(),
  }),
  z.object({
    ...effectBase, kind: z.literal("httpRequested"), method: z.string(), host: z.string().optional(),
    connectionId: z.string().optional(), status: z.number(),
  }),
  z.object({...effectBase, kind: z.literal("externalAction"), plugin: z.string(), action: z.string(), label: z.string()}),
]);

export const runEffectsSchema = z.array(z.unknown()).transform((items) =>
  items.flatMap((item) => {
    const parsed = runEffectSchema.safeParse(item);
    return parsed.success ? [parsed.data] : [];
  }));

/**
 * Innere Läufe im Journal: Die inneren Ergebnisse wurden beim Ausführen schon geprüft und dienen
 * nur dem Protokoll; sie werden daher in ihrer Form übernommen, nicht erneut validiert.
 */
export const nestedRunsSchema = z.array(z.object({
  iteration: z.number().int().nonnegative().optional(),
  results: z.array(z.record(z.string(), z.unknown())),
  failed: z.record(z.string(), z.unknown()).optional(),
}).passthrough()).transform((runs) => runs as unknown as NestedRun[]);

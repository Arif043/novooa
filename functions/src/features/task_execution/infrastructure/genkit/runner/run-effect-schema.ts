import {z} from "genkit";

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

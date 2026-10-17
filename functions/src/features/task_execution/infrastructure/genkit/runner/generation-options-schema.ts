import {z} from "genkit";
import {thinkingModes} from "../../../../language_models/domain/entities/generation-options.js";

/** Gespeicherte Generierungsoptionen eines Prompt-Bausteins; Grenzen prüft `generationOptionsFrom`. */
export const generationOptionsSchema = z.object({
  temperature: z.number().optional(),
  maxOutputTokens: z.number().optional(),
  contextWindow: z.number().optional(),
  thinking: z.enum(thinkingModes).optional(),
});

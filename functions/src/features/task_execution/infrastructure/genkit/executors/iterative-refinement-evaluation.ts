import {z} from "genkit";

export type Evaluation = {
  critique: string;
  satisfied: boolean;
};

export const evaluationSchema = z.object({
  critique: z.string(),
  satisfied: z.boolean(),
});

export function parseEvaluation(text: string): Evaluation {
  const parsed = evaluationSchema.safeParse(jsonFrom(text));
  if (parsed.success) return parsed.data;
  return {critique: text, satisfied: false};
}

function jsonFrom(text: string): unknown {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) return {};
  try {
    return JSON.parse(match[0]) as unknown;
  } catch {
    return {};
  }
}

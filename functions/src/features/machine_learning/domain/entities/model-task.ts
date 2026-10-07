/**
 * Was ein Modell löst — unabhängig davon, wie (SVM, CNN, Transformer …). Die Schlüssel folgen den
 * Pipeline-Tags von Hugging Face. Ein Katalogeintrag hat genau eine Aufgabe; kann ein Modell
 * mehrere, bekommt jede einen eigenen Eintrag mit eigenem Vertrag und geteiltem Artefakt.
 */
export const modelTasks = [
  "text-to-speech",
  "automatic-speech-recognition",
  "audio-classification",
  "image-classification",
  "object-detection",
  "image-segmentation",
  "image-to-text",
  "text-classification",
  "token-classification",
  "translation",
  "feature-extraction",
  "other",
] as const;

export type ModelTask = typeof modelTasks[number];

export function isModelTask(value: unknown): value is ModelTask {
  return typeof value === "string" && (modelTasks as readonly string[]).includes(value);
}

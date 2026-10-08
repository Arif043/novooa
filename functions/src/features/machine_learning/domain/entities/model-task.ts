/**
 * Was ein Modell löst — unabhängig davon, wie (SVM, CNN, Transformer …). Die Schlüssel folgen den
 * Pipeline-Tags von Hugging Face; eigene Schlüssel (`optical-character-recognition`,
 * `speaker-diarization`, `anomaly-detection`, `clustering`) ergänzen Aufgaben, die dort fehlen.
 * Ein Katalogeintrag hat genau eine Aufgabe; kann ein Modell mehrere, bekommt jede einen eigenen
 * Eintrag mit eigenem Vertrag und geteiltem Artefakt.
 */
export const modelTasks = [
  // Bild & Video
  "image-classification",
  "object-detection",
  "image-segmentation",
  "image-to-text",
  "optical-character-recognition",
  "document-question-answering",
  "depth-estimation",
  "keypoint-detection",
  "zero-shot-image-classification",
  "image-to-image",
  "video-classification",
  // Audio
  "text-to-speech",
  "automatic-speech-recognition",
  "audio-classification",
  "voice-activity-detection",
  "speaker-diarization",
  "audio-to-audio",
  // Text
  "text-classification",
  "token-classification",
  "translation",
  "summarization",
  "question-answering",
  "zero-shot-classification",
  "sentence-similarity",
  "text-generation",
  "feature-extraction",
  // Daten & Zeitreihen
  "tabular-classification",
  "tabular-regression",
  "time-series-forecasting",
  "anomaly-detection",
  "clustering",
  "other",
] as const;

export type ModelTask = typeof modelTasks[number];

export function isModelTask(value: unknown): value is ModelTask {
  return typeof value === "string" && (modelTasks as readonly string[]).includes(value);
}

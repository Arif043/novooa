import { modelRef, type ModelArgument } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

const minimaxProviderName = "minimax";
const defaultGoogleTextModel = "gemini-3.1-flash-lite";
const defaultGoogleReasoningModel = "gemini-3.1-flash-lite";

export function textModel(): ModelArgument {
  if (isMinimaxProvider()) return minimaxModel();
  return googleAI.model(defaultGoogleTextModel);
}

export function reasoningModel(): ModelArgument {
  if (isMinimaxProvider()) return minimaxModel();
  return googleAI.model(defaultGoogleReasoningModel);
}

export function isMinimaxProvider(): boolean {
  return process.env.AI_PROVIDER === minimaxProviderName;
}

export function modelLogContext() {
  if (isMinimaxProvider()) {
    return {
      provider: minimaxProviderName,
      model: process.env.MINIMAX_MODEL ?? "",
    };
  }
  return {
    provider: "google",
    textModel: defaultGoogleTextModel,
    reasoningModel: defaultGoogleReasoningModel,
  };
}

function minimaxModel(): ModelArgument {
  const modelName = requiredEnv("MINIMAX_MODEL");
  return modelRef({ name: `${minimaxProviderName}/${modelName}` });
}

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (value) return value;
  throw new Error(`${name} is required when AI_PROVIDER=minimax.`);
}

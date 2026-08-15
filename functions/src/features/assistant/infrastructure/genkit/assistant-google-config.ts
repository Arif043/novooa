export function assistantGoogleModelName(): string {
  return process.env.GOOGLE_TEXT_MODEL?.trim() || "gemini-3.1-flash-lite";
}

export function assistantGoogleModelConfig(): Record<string, unknown> {
  return {
    temperature: 0.2,
    tools: [{urlContext: {}}],
    toolConfig: {includeServerSideToolInvocations: true},
  };
}

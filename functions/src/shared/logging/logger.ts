export type LogData = Record<string, unknown>;

export function logInfo(event: string, data: LogData = {}): void {
  console.info(JSON.stringify({severity: "INFO", message: event, event, ...data}));
}

export function logError(event: string, data: LogData = {}): void {
  console.error(JSON.stringify({
    severity: "ERROR",
    message: `Error: ${event}`,
    event,
    ...data,
  }));
}

export function logReadableInfo(message: string): void {
  console.info(message);
}

export function logReadableError(message: string): void {
  console.error(message);
}

export function textSummary(text: string, field = "text"): LogData {
  return {[`${field}Length`]: text.length, [`${field}Preview`]: preview(text)};
}

export function errorDetails(error: unknown): unknown {
  if (error instanceof Error) {
    return {name: error.name, message: error.message, stack: error.stack};
  }
  return error;
}

function preview(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length > 160 ? `${normalized.slice(0, 157)}...` : normalized;
}

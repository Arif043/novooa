export * from "./structured-log-format.js";

export type LogData = Record<string, unknown>;

export function logInfo(event: string, data: LogData = {}): void {
  console.info(JSON.stringify({
    severity: "INFO",
    message: event,
    event,
    ...data,
  }));
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

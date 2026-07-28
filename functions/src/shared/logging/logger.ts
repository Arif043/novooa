import * as logger from "firebase-functions/logger";

export type LogData = Record<string, unknown>;

export function logInfo(event: string, data: LogData = {}): void {
  logger.info(event, {event, ...data});
}

export function logError(event: string, data: LogData = {}): void {
  logger.error(event, {event, ...data});
}

export function logException(
  event: string,
  error: unknown,
  data: LogData = {},
): void {
  logger.error(event, error, {event, ...data});
}

export async function withExceptionLogging<T>(
  event: string,
  action: () => Promise<T>,
  data: LogData = {},
): Promise<T> {
  try {
    return await action();
  } catch (error) {
    logException(event, error, data);
    throw error;
  }
}

export function logReadableInfo(message: string): void {
  logger.info(message);
}

export function logReadableError(message: string): void {
  logger.error(message);
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

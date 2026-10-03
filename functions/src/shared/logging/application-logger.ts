export type LogData = Record<string, unknown>;

export interface ApplicationLogger {
  info(event: string, data?: LogData): void;
  error(event: string, data?: LogData): void;
  exception(event: string, error: unknown, data?: LogData): void;
  /** Ein Eintrag für Menschen; [event] erlaubt der Oberfläche, bestimmte Arten (etwa Script-Ausgabe) besonders darzustellen. */
  readableInfo(message: string, event?: string): void;
  readableError(message: string, event?: string): void;
}

export async function withExceptionLogging<T>(
  logger: ApplicationLogger,
  event: string,
  action: () => Promise<T>,
  data: LogData = {},
): Promise<T> {
  try {
    return await action();
  } catch (error) {
    logger.exception(event, error, data);
    throw error;
  }
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

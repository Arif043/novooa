import {
  errorDetails,
  textSummary,
  type LogData,
  withExceptionLogging as withLoggerExceptionLogging,
} from "./application-logger.js";
import {FirebaseApplicationLogger} from "./firebase-application-logger.js";

export {errorDetails, textSummary, type LogData};

export function logInfo(event: string, data: LogData = {}): void {
  firebaseLogger().info(event, data);
}

export function logError(event: string, data: LogData = {}): void {
  firebaseLogger().error(event, data);
}

export function logException(
  event: string,
  error: unknown,
  data: LogData = {},
): void {
  firebaseLogger().exception(event, error, data);
}

export async function withExceptionLogging<T>(
  event: string,
  action: () => Promise<T>,
  data: LogData = {},
): Promise<T> {
  return withLoggerExceptionLogging(firebaseLogger(), event, action, data);
}

export function logReadableInfo(message: string): void {
  firebaseLogger().readableInfo(message);
}

export function logReadableError(message: string): void {
  firebaseLogger().readableError(message);
}

function firebaseLogger(): FirebaseApplicationLogger {
  return new FirebaseApplicationLogger();
}

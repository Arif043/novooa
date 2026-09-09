import * as firebaseLogger from "firebase-functions/logger";
import {
  type ApplicationLogger,
  type LogData,
} from "./application-logger.js";

export class FirebaseApplicationLogger implements ApplicationLogger {
  info(event: string, data: LogData = {}): void {
    firebaseLogger.info(event, {event, ...data});
  }

  error(event: string, data: LogData = {}): void {
    firebaseLogger.error(event, {event, ...data});
  }

  exception(event: string, error: unknown, data: LogData = {}): void {
    firebaseLogger.error(event, error, {event, ...data});
  }

  readableInfo(message: string): void {
    firebaseLogger.info(message);
  }

  readableError(message: string): void {
    firebaseLogger.error(message);
  }
}

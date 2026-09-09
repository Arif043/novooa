import {randomUUID} from "node:crypto";
import {
  errorDetails,
  type ApplicationLogger,
  type LogData,
} from "./application-logger.js";
import {
  type ApplicationLogLevel,
  type LocalApplicationLog,
  type LocalApplicationLogStore,
} from "./local-application-log-store.js";

export type LocalApplicationLoggerOptions = {
  clock?: () => Date;
  writeToConsole?: boolean;
};

export class LocalApplicationLogger implements ApplicationLogger {
  private writes: Promise<void> = Promise.resolve();
  private readonly clock: () => Date;
  private readonly writeToConsole: boolean;

  constructor(
    private readonly store: LocalApplicationLogStore,
    private readonly teamId: string,
    options: LocalApplicationLoggerOptions = {},
  ) {
    this.clock = options.clock ?? (() => new Date());
    this.writeToConsole = options.writeToConsole ?? true;
  }

  info(event: string, data: LogData = {}): void {
    this.write("info", event, null, data);
  }

  error(event: string, data: LogData = {}): void {
    this.write("error", event, null, data);
  }

  exception(event: string, error: unknown, data: LogData = {}): void {
    this.write("error", event, null, {...data, error: errorDetails(error)});
  }

  readableInfo(message: string): void {
    this.write("info", "application.message", message);
  }

  readableError(message: string): void {
    this.write("error", "application.message", message);
  }

  async flush(): Promise<void> {
    await this.writes;
  }

  private write(
    level: ApplicationLogLevel,
    event: string,
    message: string | null,
    data: LogData = {},
  ): void {
    const log = this.log(level, event, message, data);
    this.writeToConsole ? writeToConsole(log) : undefined;
    this.writes = this.writes.then(
      () => this.store.append(log),
      () => this.store.append(log),
    ).catch((error: unknown) => reportStoreFailure(error));
  }

  private log(
    level: ApplicationLogLevel,
    event: string,
    message: string | null,
    data: LogData,
  ): LocalApplicationLog {
    return {
      id: randomUUID(),
      teamId: this.teamId,
      level,
      event,
      message,
      data,
      occurredAt: this.clock().toISOString(),
    };
  }
}

function writeToConsole(log: LocalApplicationLog): void {
  try {
    const line = JSON.stringify(log);
    log.level === "error" ? console.error(line) : console.info(line);
  } catch (error) {
    reportStoreFailure(error);
  }
}

function reportStoreFailure(error: unknown): void {
  console.error(JSON.stringify({
    event: "local_application_log.write_failed",
    error: errorDetails(error),
  }));
}

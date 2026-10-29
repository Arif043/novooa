import {type Client, LibsqlError, type Transaction} from "@libsql/client";

/**
 * Wie lange ein Zugriff höchstens in der Schlange wartet. Wird das überschritten, hält vermutlich
 * Code innerhalb einer Transaktion die äußere Datenbank statt `tx` — dann lieber ein klarer Fehler
 * als eine Runtime, die für immer steht.
 */
export const maximumQueueWaitMs = 30_000;

const shortOperations = new Set<PropertyKey>(["execute", "batch", "executeMultiple", "migrate"]);

/**
 * Ein libSQL-Client mit genau einer Verbindung, deren Zugriffe sich der Reihe nach anstellen.
 *
 * SQLite verträgt in einem Prozess nur einen Schreiber zur Zeit, und libSQL wartet bei einer
 * Sperre synchron: Eine zweite Verbindung, die wartet, blockiert den ganzen Node-Prozess — auch
 * die Transaktion, die die Sperre hält. Mit einer Verbindung und dieser asynchronen Schlange
 * wartet ein Zugriff stattdessen, bis die laufende Transaktion fertig ist.
 */
export function serializedLibsqlClient(client: Client, waitLimitMs = maximumQueueWaitMs): Client {
  const queue = new OperationQueue(waitLimitMs);
  return new Proxy(client, {
    get(target, property) {
      const value: unknown = Reflect.get(target, property);
      if (typeof value !== "function") return value;
      if (shortOperations.has(property)) {
        return (...args: unknown[]) => queue.run(() => (value as (...a: unknown[]) => Promise<unknown>).apply(target, args));
      }
      if (property === "transaction") {
        return async (...args: unknown[]) => heldTransaction(await queue.acquire(), () => target.transaction(...(args as Parameters<Client["transaction"]>)));
      }
      return (value as (...a: unknown[]) => unknown).bind(target);
    },
  });
}

/** Die Transaktion hält ihren Platz in der Schlange, bis sie bestätigt, verworfen oder geschlossen ist. */
async function heldTransaction(release: () => void, open: () => Promise<Transaction>): Promise<Transaction> {
  let transaction: Transaction;
  try {
    transaction = await open();
  } catch (error) {
    release();
    throw error;
  }
  let released = false;
  const finish = () => {
    if (released) return;
    released = true;
    release();
  };
  return new Proxy(transaction, {
    get(target, property) {
      const value: unknown = Reflect.get(target, property);
      if (typeof value !== "function") return value;
      const method = value as (...a: unknown[]) => unknown;
      if (property === "commit" || property === "rollback") {
        return async (...args: unknown[]) => {
          try {
            return await method.apply(target, args);
          } finally {
            finish();
          }
        };
      }
      if (property === "close") {
        return (...args: unknown[]) => {
          try {
            return method.apply(target, args);
          } finally {
            finish();
          }
        };
      }
      return method.bind(target);
    },
  });
}

/** Eine faire Warteschlange: Wer zuerst kommt, bekommt die Verbindung zuerst. */
class OperationQueue {
  private tail: Promise<void> = Promise.resolve();

  constructor(private readonly waitLimitMs: number) {}

  async run<T>(operation: () => Promise<T>): Promise<T> {
    const release = await this.acquire();
    try {
      return await operation();
    } finally {
      release();
    }
  }

  acquire(): Promise<() => void> {
    let release!: () => void;
    const turnEnds = new Promise<void>((resolve) => (release = resolve));
    const myTurn = this.tail;
    this.tail = this.tail.then(() => turnEnds);
    return withWaitLimit(myTurn.then(() => release), this.waitLimitMs, release);
  }
}

function withWaitLimit(turn: Promise<() => void>, limitMs: number, giveUp: () => void): Promise<() => void> {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      // Den eigenen Platz freigeben, damit die Schlange nach dem Vorgänger weiterläuft.
      giveUp();
      reject(new LibsqlError(
        `Die Datenbank war länger als ${limitMs} ms belegt. Läuft Code in einer Transaktion über die äußere Datenbank statt über tx?`,
        "SQLITE_BUSY",
      ));
    }, limitMs);
  });
  return Promise.race([turn, timeout]).finally(() => clearTimeout(timer));
}

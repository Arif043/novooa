/** Führt Operationen nacheinander aus, damit der In-Memory-Store Transaktionen nachbildet. */
export class SerialQueue {
  private tail: Promise<void> = Promise.resolve();

  run<T>(operation: () => T): Promise<T> {
    const completed = this.tail.then(operation, operation);
    this.tail = completed.then(() => undefined, () => undefined);
    return completed;
  }
}

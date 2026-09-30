export class RuntimeSecretFileAccess {
  private queue: Promise<void> = Promise.resolve();

  run<T>(operation: () => Promise<T>): Promise<T> {
    const completed = this.queue.then(operation, operation);
    this.queue = completed.then(() => undefined, () => undefined);
    return completed;
  }
}

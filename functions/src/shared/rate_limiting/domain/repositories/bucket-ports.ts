import {type BucketConfig, type BucketState} from "../entities/token-bucket.js";

/** Die Werte des Eimers, zur Laufzeit änderbar (Firebase Remote Config). */
export interface BucketSettings {
  current(): Promise<BucketConfig>;
}

/** Speicher der Eimer; `transact` ist atomar je Schlüssel, damit parallele Anfragen kein Token doppelt verbrauchen. */
export interface BucketStateStore {
  /** `mutate` liefert den neuen Zustand oder `undefined`, wenn nichts zu speichern ist. */
  transact<Result>(
    key: string,
    mutate: (state: BucketState | undefined) => {next?: BucketState; result: Result},
  ): Promise<Result>;
}

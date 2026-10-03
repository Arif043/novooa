/** Ausgang einer Operation, die auf eine erwartbare Weise scheitern kann: Wert oder Failure, nie eine Exception. */
export type Result<Success, Failure> =
  | {readonly ok: true; readonly value: Success}
  | {readonly ok: false; readonly failure: Failure};

export function success<Success>(value: Success): Result<Success, never> {
  return {ok: true, value};
}

export function failure<Failure>(reason: Failure): Result<never, Failure> {
  return {ok: false, failure: reason};
}

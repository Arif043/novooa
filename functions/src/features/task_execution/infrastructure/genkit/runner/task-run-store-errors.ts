import {UserFacingError} from "genkit";

export function invalidReviewState() {
  return new UserFacingError(
    "FAILED_PRECONDITION",
    "Diese Ausführung wartet nicht auf eine Freigabe.",
  );
}

export function invalidResumeState() {
  return new UserFacingError(
    "FAILED_PRECONDITION",
    "Diese Ausführung kann nicht fortgesetzt werden.",
  );
}

export function runNotFound() {
  return new UserFacingError("NOT_FOUND", "Ausführung wurde nicht gefunden.");
}

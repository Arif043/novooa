import {err, ok, type Result} from "neverthrow";
import {
  type DocumentFilterOperator,
  type DocumentFilterValue,
  isNumericOperator,
} from "../../../data/domain/entities/document-filter.js";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";

/** Der aufgelöste Vergleichswert einer Feldbedingung (Datensatz suchen/speichern). */
export function documentFilterValueFor(
  operator: DocumentFilterOperator,
  value: unknown,
): Result<DocumentFilterValue, NodeFailure> {
  if (isNumericOperator(operator)) return numberValueFor(value);
  if (typeof value === "string" || typeof value === "boolean") return ok(value);
  if (typeof value === "number" && Number.isFinite(value)) return ok(value);
  return err(nodeFailures.settingInvalid("documentFilterValue"));
}

function numberValueFor(value: unknown): Result<number, NodeFailure> {
  if (typeof value === "number" && Number.isFinite(value)) return ok(value);
  const number = typeof value === "string" && value.trim().length > 0 ? Number(value) : NaN;
  return Number.isFinite(number) ? ok(number) : err(nodeFailures.valueTypeMismatch("documentFilter", "number"));
}

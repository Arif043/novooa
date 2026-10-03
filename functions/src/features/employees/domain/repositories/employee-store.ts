import {type Employee, type EmployeeInput} from "../entities/employee.js";

/** Mitarbeiter eines Teams. */
export interface EmployeeStore {
  /** Alphabetisch nach Name. */
  list(teamId: string): Promise<Employee[]>;
  /** `null`, wenn es den Mitarbeiter nicht gibt. */
  find(teamId: string, employeeId: string): Promise<Employee | null>;
  create(teamId: string, input: EmployeeInput): Promise<Employee>;
  /** `null`, wenn es den Mitarbeiter nicht gibt. */
  update(teamId: string, employeeId: string, input: EmployeeInput): Promise<Employee | null>;
  /** `false`, wenn es den Mitarbeiter nicht gibt. */
  delete(teamId: string, employeeId: string): Promise<boolean>;
}

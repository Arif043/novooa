import {type RuntimeDatabase} from "../../../../db/database.js";
import {CreateEmployee, DeleteEmployee, ListEmployees, UpdateEmployee} from "../../domain/usecases/employee-library.js";
import {type EmployeeRoutesOptions} from "./local-employee-routes.js";
import {SQLiteEmployeeStore} from "./sqlite-employee-store.js";

export function createEmployeeRoutesOptions(database: RuntimeDatabase, notifier: EmployeeRoutesOptions["notifier"]): EmployeeRoutesOptions {
  const store = new SQLiteEmployeeStore(database);
  return {
    list: new ListEmployees(store),
    create: new CreateEmployee(store),
    update: new UpdateEmployee(store),
    remove: new DeleteEmployee(store),
    notifier,
  };
}

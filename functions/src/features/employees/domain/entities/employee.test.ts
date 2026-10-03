import assert from "node:assert/strict";
import test from "node:test";
import {employeeInputFrom, employeeLimits, EmployeeValidationError, isSkillFolderName, sameEmployeeName} from "./employee.js";

const valid = {name: "Rezeption", constraint: "Du bist freundlich.", skills: ["mails", "pdf"]};

test("valid input is trimmed and skills are de-duplicated in order", () => {
  assert.deepEqual(
    employeeInputFrom({name: "  Rezeption ", constraint: "  Sei knapp.\n", skills: [" mails", "pdf", "mails "]}),
    {name: "Rezeption", constraint: "Sei knapp.", skills: ["mails", "pdf"]},
  );
});

test("the constraint may be empty, an employee may have no skills", () => {
  assert.deepEqual(employeeInputFrom({name: "Nur Name", constraint: "", skills: []}), {name: "Nur Name", constraint: "", skills: []});
});

test("a missing or too long name is rejected readably", () => {
  assert.throws(() => employeeInputFrom({...valid, name: "   "}), /Gib dem Mitarbeiter einen Namen/);
  assert.throws(() => employeeInputFrom({...valid, name: "x".repeat(employeeLimits.maximumNameLength + 1)}), /Name ist zu lang/);
  assert.doesNotThrow(() => employeeInputFrom({...valid, name: "x".repeat(employeeLimits.maximumNameLength)}));
});

test("the constraint and the number of skills are limited", () => {
  assert.throws(() => employeeInputFrom({...valid, constraint: "x".repeat(employeeLimits.maximumConstraintLength + 1)}), /Rahmenbedingung ist zu lang/);
  const many = Array.from({length: employeeLimits.maximumSkills + 1}, (_, index) => `skill-${index}`);
  assert.throws(() => employeeInputFrom({...valid, skills: many}), /Zu viele Fähigkeiten/);
  assert.doesNotThrow(() => employeeInputFrom({...valid, skills: many.slice(1)}));
});

test("skill names must be plain folder names", () => {
  for (const bad of ["", "../pdf", "a/b", "a\\b", ".versteckt", "x".repeat(256)]) {
    assert.equal(isSkillFolderName(bad), false, bad);
  }
  assert.equal(isSkillFolderName("pdf-verarbeitung"), true);
  assert.throws(() => employeeInputFrom({...valid, skills: ["../ausbruch"]}), (error: unknown) =>
    error instanceof EmployeeValidationError && /„..\/ausbruch“ ist ungültig/.test(error.message));
  assert.throws(() => employeeInputFrom({...valid, skills: [" "]}), EmployeeValidationError);
});

test("names are compared without case and surrounding spaces", () => {
  assert.equal(sameEmployeeName("Rezeption", " rezeption "), true);
  assert.equal(sameEmployeeName("Äpfel", "äPFEL"), true);
  assert.equal(sameEmployeeName("Rezeption", "Rezeption 2"), false);
});

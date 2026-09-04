import {type EmployeeAttachment} from "./task.js";

export type IterativeRefinementRequest = {
  objective: string;
  draft: string;
  optimizerPrompt: string;
  critiquePrompt: string;
  maxIterations: number;
  employee?: EmployeeAttachment;
};

export type IterativeRefinementResult = {
  answer: string;
  iterations: number;
};

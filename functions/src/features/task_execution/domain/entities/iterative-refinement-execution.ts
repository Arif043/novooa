import {type ResolvedEmployee} from "./task.js";

export type IterativeRefinementRequest = {
  objective: string;
  draft: string;
  optimizerPrompt: string;
  critiquePrompt: string;
  maxIterations: number;
  employee?: ResolvedEmployee;
};

export type IterativeRefinementResult = {
  answer: string;
  iterations: number;
};

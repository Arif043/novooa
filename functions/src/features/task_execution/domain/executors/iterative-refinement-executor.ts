import {
  type IterativeRefinementRequest,
  type IterativeRefinementResult,
} from "../entities/iterative-refinement-execution.js";

export interface IterativeRefinementExecutor {
  execute(request: IterativeRefinementRequest): Promise<IterativeRefinementResult>;
}

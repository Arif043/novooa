import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";

export class LocalRuntimeRequestRouter implements LocalRuntimeRequestHandler {
  constructor(private readonly handlers: LocalRuntimeRequestHandler[]) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    for (const handler of this.handlers) {
      const response = await handler.handle(request);
      if (response !== null) return response;
    }
    return null;
  }
}

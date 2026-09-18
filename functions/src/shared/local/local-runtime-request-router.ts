import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
  type LocalRuntimeStreamRequest,
  type LocalRuntimeStreamRequestHandler,
} from "./local-runtime-http-server.js";

export class LocalRuntimeRequestRouter implements LocalRuntimeRequestHandler, LocalRuntimeStreamRequestHandler {
  constructor(private readonly handlers: LocalRuntimeRequestHandler[]) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    for (const handler of this.handlers) {
      const response = await handler.handle(request);
      if (response !== null) return response;
    }
    return null;
  }

  async handleStream(request: LocalRuntimeStreamRequest): Promise<LocalRuntimeResponse | null> {
    for (const handler of this.handlers) {
      if (!isStreamHandler(handler)) continue;
      const response = await handler.handleStream(request);
      if (response !== null) return response;
    }
    return null;
  }
}

function isStreamHandler(handler: LocalRuntimeRequestHandler): handler is LocalRuntimeRequestHandler & LocalRuntimeStreamRequestHandler {
  return "handleStream" in handler;
}

export function valueAtJsonPointer(value: unknown, pointer: string): unknown {
  if (pointer === "") return value;
  if (!pointer.startsWith("/")) {
    throw new Error("Der JSON-Pointer muss mit / beginnen.");
  }
  return pointer.slice(1).split("/").reduce(pointerSegment, value);
}

function pointerSegment(value: unknown, encodedSegment: string): unknown {
  const segment = encodedSegment.replace(/~1/g, "/").replace(/~0/g, "~");
  if (Array.isArray(value)) return arrayValue(value, segment);
  if (value !== null && typeof value === "object") {
    return (value as Record<string, unknown>)[segment];
  }
  return undefined;
}

function arrayValue(value: unknown[], segment: string): unknown {
  if (!/^(0|[1-9][0-9]*)$/.test(segment)) return undefined;
  return value[Number(segment)];
}

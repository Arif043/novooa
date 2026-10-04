// Brücke zwischen dem Flutter-Client und jscanify/OpenCV.js. Die schweren Bibliotheken (ca. 9 MB)
// werden erst beim ersten Scan nachgeladen, nicht beim Start der App.
const DETECTION_WIDTH = 480;
const MAX_RESULT_SIDE = 2400;
const MIN_AREA_RATIO = 0.15;
const MAX_AREA_RATIO = 0.97;
const JPEG_QUALITY = 0.92;
// Die erkannte Kontur liegt auf dem Papierrand; ein kleiner Einzug verhindert einen Streifen vom Tisch im Ergebnis.
const EDGE_INSET = 0.006;

const baseUrl = new URL('./', import.meta.url);
let enginePromise;
let scanner;
let detectionCanvas;

globalThis.novooaDocumentScanner = {
  init() {
    enginePromise ??= loadEngine();
    return enginePromise;
  },
  detect(video) {
    return scanner ? detectQuad(video) : null;
  },
  capture(video, quadJson) {
    return captureJpeg(video, quadJson);
  },
};

async function loadEngine() {
  await loadScript('opencv.js');
  await openCvReady();
  await loadScript('jscanify.js');
  scanner = new globalThis.jscanify();
  detectionCanvas = document.createElement('canvas');
}

function loadScript(name) {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = new URL(name, baseUrl).href;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error(`${name} konnte nicht geladen werden.`));
    document.head.appendChild(script);
  });
}

// OpenCV.js meldet sich je nach Build als Promise oder über einen Rückruf. Das Promise wird nie mit
// dem Modul selbst aufgelöst, weil das Modul `then` besitzt und sonst endlos weiter auflöst.
function openCvReady() {
  return new Promise((resolve) => {
    if (typeof globalThis.cv?.then === 'function') {
      globalThis.cv.then((module) => {
        globalThis.cv = module;
        resolve();
      });
    } else if (globalThis.cv?.Mat) {
      resolve();
    } else {
      globalThis.cv.onRuntimeInitialized = () => resolve();
    }
  });
}

function detectQuad(video) {
  const frame = drawFrame(video, DETECTION_WIDTH);
  if (!frame) return null;
  const image = cv.imread(frame.canvas);
  try {
    const contour = scanner.findPaperContour(image);
    if (!contour) return null;
    try {
      return quadJsonFrom(scanner.getCornerPoints(contour), frame.canvas);
    } finally {
      contour.delete();
    }
  } finally {
    image.delete();
  }
}

// Ecken als Anteil der Bildgröße (0..1), Reihenfolge: links oben, rechts oben, rechts unten, links unten.
function quadJsonFrom(corners, canvas) {
  const {topLeftCorner: a, topRightCorner: b, bottomRightCorner: c, bottomLeftCorner: d} = corners;
  if (!a || !b || !c || !d) return null;
  const area = polygonArea([a, b, c, d]) / (canvas.width * canvas.height);
  if (area < MIN_AREA_RATIO || area > MAX_AREA_RATIO) return null;
  const share = (p) => [p.x / canvas.width, p.y / canvas.height];
  return JSON.stringify([...share(a), ...share(b), ...share(c), ...share(d)]);
}

async function captureJpeg(video, quadJson) {
  const frame = drawFrame(video, Infinity);
  if (!frame) throw new Error('Kein Kamerabild verfügbar.');
  const source = quadJson ? flattened(frame.canvas, JSON.parse(quadJson)) : frame.canvas;
  const blob = await new Promise((resolve) => source.toBlob(resolve, 'image/jpeg', JPEG_QUALITY));
  if (!blob) throw new Error('Das Bild konnte nicht erzeugt werden.');
  return blob.arrayBuffer();
}

function flattened(canvas, quad) {
  const [a, b, c, d] = insetTowardCenter(
    [0, 2, 4, 6].map((i) => ({x: quad[i] * canvas.width, y: quad[i + 1] * canvas.height})),
  );
  const size = resultSize(a, b, c, d);
  return scanner.extractPaper(canvas, size.width, size.height, {
    topLeftCorner: a, topRightCorner: b, bottomRightCorner: c, bottomLeftCorner: d,
  });
}

function insetTowardCenter(points) {
  const center = {
    x: points.reduce((sum, p) => sum + p.x, 0) / points.length,
    y: points.reduce((sum, p) => sum + p.y, 0) / points.length,
  };
  return points.map((p) => ({x: p.x + (center.x - p.x) * EDGE_INSET, y: p.y + (center.y - p.y) * EDGE_INSET}));
}

function resultSize(a, b, c, d) {
  const width = Math.max(distance(a, b), distance(d, c));
  const height = Math.max(distance(a, d), distance(b, c));
  const scale = Math.min(1, MAX_RESULT_SIDE / Math.max(width, height));
  return {width: Math.round(width * scale), height: Math.round(height * scale)};
}

function drawFrame(video, maxWidth) {
  const {videoWidth: width, videoHeight: height} = video;
  if (!width || !height) return null;
  const scale = Math.min(1, maxWidth / width);
  const canvas = maxWidth === Infinity ? document.createElement('canvas') : detectionCanvas;
  canvas.width = Math.round(width * scale);
  canvas.height = Math.round(height * scale);
  canvas.getContext('2d', {willReadFrequently: true}).drawImage(video, 0, 0, canvas.width, canvas.height);
  return {canvas};
}

function distance(p, q) {
  return Math.hypot(p.x - q.x, p.y - q.y);
}

function polygonArea(points) {
  const twice = points.reduce((sum, p, i) => {
    const next = points[(i + 1) % points.length];
    return sum + (p.x * next.y - next.x * p.y);
  }, 0);
  return Math.abs(twice) / 2;
}

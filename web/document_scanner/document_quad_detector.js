// Sucht ein Blatt als Viereck im Bild. Reine OpenCV-Logik ohne DOM, damit sie auch in Node testbar ist.
// Ergebnis: vier Ecken in Pixeln, Reihenfolge links oben, rechts oben, rechts unten, links unten.
const MIN_AREA_RATIO = 0.15;
const MAX_AREA_RATIO = 0.97;
const MAX_CANDIDATES = 10;
const APPROX_EPSILONS = [0.02, 0.03, 0.04, 0.05];
const MIN_ANGLE = 30;
const MAX_ANGLE = 150;
// Konturpunkte nahe der Ecken gehören oft zu Rundungen oder Fingern; die Geraden passen nur auf die Mitte der Seiten.
const SIDE_MARGIN = 0.12;
// Großzügig, weil Kassenbons und gefaltetes Papier eingerissene, gewellte Ränder haben.
const SIDE_TOLERANCE = 0.04;
// Weicht ein Geradenschnitt so weit von der groben Ecke ab, ist die Gerade unzuverlässig.
const MAX_REFINE_SHIFT = 0.04;
// Eine echte Blattseite liegt fast durchgehend auf der Kontur. Seiten, die die konvexe Hülle nur über
// Lücken spannt (verschmolzene Konturen, Muster im Untergrund), sind keine Blattkanten.
const MIN_SIDE_COVERAGE = 0.45;
const COVERAGE_BINS = 40;
// Liegt eine Seite auf dem Bildrand, ist es eine angeschnittene Fläche (Boden, Tisch), kein ganzes Blatt.
const BORDER_MARGIN = 0.01;

export function findDocumentQuad(cv, rgba) {
  const gray = grayscale(cv, rgba);
  try {
    const imageArea = rgba.cols * rgba.rows;
    for (const edgeMap of [cannyEdges, otsuMask]) {
      const quad = withMat(edgeMap(cv, gray), (mask) => largestQuad(cv, mask, imageArea));
      if (quad) return quad;
    }
    return null;
  } finally {
    gray.delete();
  }
}

function grayscale(cv, rgba) {
  const gray = new cv.Mat();
  cv.cvtColor(rgba, gray, cv.COLOR_RGBA2GRAY);
  cv.GaussianBlur(gray, gray, new cv.Size(5, 5), 0, 0, cv.BORDER_DEFAULT);
  return gray;
}

// Kantenschwellen aus dem Median passen sich an helle und dunkle Szenen an.
function cannyEdges(cv, gray) {
  const median = medianOf(gray.data);
  const edges = new cv.Mat();
  cv.Canny(gray, edges, Math.max(10, 0.66 * median), Math.min(255, 1.33 * median));
  const kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(5, 5));
  cv.morphologyEx(edges, edges, cv.MORPH_CLOSE, kernel);
  kernel.delete();
  return edges;
}

// Rückfall für weiche Kanten: helles Papier hebt sich als Fläche vom Untergrund ab.
function otsuMask(cv, gray) {
  const mask = new cv.Mat();
  cv.threshold(gray, mask, 0, 255, cv.THRESH_BINARY + cv.THRESH_OTSU);
  return mask;
}

function medianOf(pixels) {
  const histogram = new Uint32Array(256);
  for (let i = 0; i < pixels.length; i++) histogram[pixels[i]]++;
  let seen = 0;
  for (let value = 0; value < 256; value++) {
    seen += histogram[value];
    if (seen * 2 >= pixels.length) return value;
  }
  return 128;
}

function largestQuad(cv, mask, imageArea) {
  const contours = new cv.MatVector();
  const hierarchy = new cv.Mat();
  try {
    cv.findContours(mask, contours, hierarchy, cv.RETR_LIST, cv.CHAIN_APPROX_NONE);
    for (const index of largestContourIndices(cv, contours)) {
      const quad = withMat(contours.get(index), (contour) => quadFrom(cv, contour, mask, imageArea));
      if (quad) return quad;
    }
    return null;
  } finally {
    contours.delete();
    hierarchy.delete();
  }
}

function largestContourIndices(cv, contours) {
  const areas = [];
  for (let i = 0; i < contours.size(); i++) {
    areas.push({index: i, area: withMat(contours.get(i), (contour) => cv.contourArea(contour))});
  }
  return areas.sort((a, b) => b.area - a.area).slice(0, MAX_CANDIDATES).map((entry) => entry.index);
}

function quadFrom(cv, contour, mask, imageArea) {
  const rough = withMat(hullOf(cv, contour), (hull) => fourCorners(cv, hull));
  if (!rough) return null;
  const area = polygonArea(rough) / imageArea;
  if (area < MIN_AREA_RATIO || area > MAX_AREA_RATIO || !hasPlausibleAngles(rough)) return null;
  if (hasSideOnBorder(rough, mask)) return null;
  return refineCorners(cv, rough, contourPoints(contour), mask);
}

function hasSideOnBorder(corners, mask) {
  const margin = BORDER_MARGIN * Math.max(mask.cols, mask.rows);
  const onBorder = [
    (p) => p.x <= margin,
    (p) => p.y <= margin,
    (p) => p.x >= mask.cols - 1 - margin,
    (p) => p.y >= mask.rows - 1 - margin,
  ];
  return corners.some((corner, i) => {
    const next = corners[(i + 1) % 4];
    return onBorder.some((isOn) => isOn(corner) && isOn(next));
  });
}

function hullOf(cv, contour) {
  const hull = new cv.Mat();
  cv.convexHull(contour, hull, false, true);
  return hull;
}

function fourCorners(cv, hull) {
  const perimeter = cv.arcLength(hull, true);
  for (const epsilon of APPROX_EPSILONS) {
    const corners = withMat(new cv.Mat(), (approx) => {
      cv.approxPolyDP(hull, approx, epsilon * perimeter, true);
      return approx.rows === 4 && cv.isContourConvex(approx) ? contourPoints(approx) : null;
    });
    if (corners) return orderClockwise(corners);
  }
  return null;
}

// Gerade durch die Mitte jeder Seite, Ecken als Schnittpunkte: genauer als einzelne Konturpixel.
function refineCorners(cv, rough, points, mask) {
  const lines = rough.map((start, i) => fitSide(cv, start, rough[(i + 1) % 4], points));
  if (lines.some((line) => !line)) return null;
  const limit = MAX_REFINE_SHIFT * Math.hypot(mask.cols, mask.rows);
  return rough.map((corner, i) => {
    const refined = intersect(lines[(i + 3) % 4], lines[i]);
    return refined && distance(refined, corner) <= limit ? refined : corner;
  });
}

function fitSide(cv, start, end, points) {
  const length = distance(start, end);
  const onSide = points.filter((p) => isOnSide(p, start, end, length));
  if (sideCoverage(onSide, start, end, length) < MIN_SIDE_COVERAGE) return null;
  const pointMat = cv.matFromArray(onSide.length, 1, cv.CV_32FC2, onSide.flatMap((p) => [p.x, p.y]));
  const line = new cv.Mat();
  try {
    cv.fitLine(pointMat, line, cv.DIST_HUBER, 0, 0.01, 0.01);
    const [vx, vy, x, y] = line.data32F;
    return {vx, vy, x, y};
  } finally {
    pointMat.delete();
    line.delete();
  }
}

function isOnSide(point, start, end, length) {
  const dx = (end.x - start.x) / length;
  const dy = (end.y - start.y) / length;
  const along = ((point.x - start.x) * dx + (point.y - start.y) * dy) / length;
  const across = Math.abs((point.x - start.x) * dy - (point.y - start.y) * dx);
  return along > SIDE_MARGIN && along < 1 - SIDE_MARGIN && across <= SIDE_TOLERANCE * length + 2;
}

// Anteil der Seitenmitte, unter dem tatsächlich Konturpunkte liegen.
function sideCoverage(onSide, start, end, length) {
  const hit = new Set();
  for (const point of onSide) {
    const along = ((point.x - start.x) * (end.x - start.x) + (point.y - start.y) * (end.y - start.y)) / length ** 2;
    hit.add(Math.floor(((along - SIDE_MARGIN) / (1 - 2 * SIDE_MARGIN)) * COVERAGE_BINS));
  }
  return hit.size / COVERAGE_BINS;
}

function intersect(a, b) {
  const denominator = a.vx * b.vy - a.vy * b.vx;
  if (Math.abs(denominator) < 1e-6) return null;
  const t = ((b.x - a.x) * b.vy - (b.y - a.y) * b.vx) / denominator;
  return {x: a.x + t * a.vx, y: a.y + t * a.vy};
}

// Sortiert nach dem Winkel um den Schwerpunkt; auch gedrehte Blätter beginnen links oben.
function orderClockwise(points) {
  const cx = points.reduce((sum, p) => sum + p.x, 0) / points.length;
  const cy = points.reduce((sum, p) => sum + p.y, 0) / points.length;
  const sorted = [...points].sort((p, q) => Math.atan2(p.y - cy, p.x - cx) - Math.atan2(q.y - cy, q.x - cx));
  const first = sorted.reduce((best, p, i) => (p.x + p.y < sorted[best].x + sorted[best].y ? i : best), 0);
  return [...sorted.slice(first), ...sorted.slice(0, first)];
}

function hasPlausibleAngles(corners) {
  return corners.every((corner, i) => {
    const previous = corners[(i + 3) % 4];
    const next = corners[(i + 1) % 4];
    const angle = angleBetween(previous, corner, next);
    return angle >= MIN_ANGLE && angle <= MAX_ANGLE;
  });
}

function angleBetween(a, vertex, b) {
  const first = Math.atan2(a.y - vertex.y, a.x - vertex.x);
  const second = Math.atan2(b.y - vertex.y, b.x - vertex.x);
  const degrees = Math.abs(first - second) * (180 / Math.PI);
  return degrees > 180 ? 360 - degrees : degrees;
}

function contourPoints(mat) {
  const points = [];
  for (let i = 0; i < mat.data32S.length; i += 2) {
    points.push({x: mat.data32S[i], y: mat.data32S[i + 1]});
  }
  return points;
}

export function polygonArea(points) {
  const twice = points.reduce((sum, p, i) => {
    const next = points[(i + 1) % points.length];
    return sum + (p.x * next.y - next.x * p.y);
  }, 0);
  return Math.abs(twice) / 2;
}

function distance(p, q) {
  return Math.hypot(p.x - q.x, p.y - q.y);
}

function withMat(mat, use) {
  try {
    return use(mat);
  } finally {
    mat.delete();
  }
}

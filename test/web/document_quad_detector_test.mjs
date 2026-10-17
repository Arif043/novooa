// Prüft die Blatterkennung des Browser-Scanners auf künstlichen Kamerabildern.
// Ausführen: node --test test/web/
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {before, test} from 'node:test';

import {findDocumentQuad} from '../../web/document_scanner/document_quad_detector.js';

const WIDTH = 640;
const HEIGHT = 480;
const TOLERANCE = 0.01 * WIDTH;
let cv;

before(async () => {
  const loaded = createRequire(import.meta.url)('../../web/document_scanner/opencv.js');
  cv = await openCvReady(loaded);
});

function openCvReady(module) {
  if (module.Mat) return Promise.resolve(module);
  if (typeof module.then === 'function') {
    return new Promise((resolve) => module.then((ready) => resolve(withoutThen(ready))));
  }
  return new Promise((resolve) => (module.onRuntimeInitialized = () => resolve(module)));
}

// Das Modul hat selbst ein `then`; ohne es aufzulösen, würde das Promise endlos weiterlaufen.
function withoutThen(module) {
  delete module.then;
  return module;
}

test('findet ein gedrehtes Blatt auf dunklem, verrauschtem Grund', () => {
  const corners = [p(150, 70), p(470, 110), p(440, 420), p(110, 380)];
  assertFound(scene({background: 60, paper: 230, corners}), corners);
});

test('findet ein perspektivisch verzerrtes Blatt', () => {
  const corners = [p(220, 60), p(420, 60), p(560, 440), p(80, 440)];
  assertFound(scene({background: 90, paper: 220, corners}), corners);
});

test('liefert die Ecken links oben beginnend auch bei starker Drehung', () => {
  const corners = [p(320, 40), p(560, 240), p(320, 440), p(80, 240)];
  const found = detect(scene({background: 50, paper: 235, corners}));
  assert.ok(found, 'kein Blatt gefunden');
  assert.ok(found[0].x + found[0].y <= Math.min(...found.map((c) => c.x + c.y)) + 1);
});

test('lässt sich von einem Finger über der Kante nicht verschieben', () => {
  const corners = [p(140, 80), p(500, 80), p(500, 420), p(140, 420)];
  const image = scene({background: 70, paper: 230, corners});
  fill(image, [p(300, 380), p(340, 380), p(345, 479), p(295, 479)], 150);
  assertFound(image, corners);
});

test('findet weißes Papier auf hellgrauem Tisch', () => {
  const corners = [p(130, 90), p(510, 100), p(500, 400), p(120, 390)];
  assertFound(scene({background: 175, paper: 240, corners}), corners);
});

test('greift bei gestreiftem Untergrund nicht auf das Muster daneben', () => {
  const corners = [p(140, 80), p(500, 90), p(490, 420), p(150, 410)];
  const image = scene({background: 90, paper: 230, corners: null});
  for (let y = 0; y < HEIGHT; y += 24) fill(image, [p(0, y), p(WIDTH - 1, y), p(WIDTH - 1, y + 3), p(0, y + 3)], 140);
  fill(image, corners, 230);
  assertFound(image, corners);
});

test('findet einen Kassenbon mit eingerissener Unterkante und umgeknickter Ecke', () => {
  const corners = [p(220, 40), p(420, 60), p(400, 440), p(200, 420)];
  // Unregelmäßiger Abriss; links unten ist die Ecke nach außen umgeknickt.
  const tear = [0, 6, 14, 9, 16, 4, 12, 18, 7, 13, 3, 15, 8, 17, 10];
  const torn = tear.map((offset, i) => {
    const t = i / (tear.length - 1);
    return p(400 - 200 * t, 440 - 20 * t + offset - 8);
  });
  const image = scene({background: 45, paper: 225, corners: null});
  fill(image, [corners[0], corners[1], ...torn.slice(0, -3), p(170, 452), p(200, 404)], 225);
  assertFound(image, corners, 0.04 * WIDTH);
});

test('nimmt keine helle Fläche, die am Bildrand angeschnitten ist', () => {
  const floor = [p(0, 300), p(639, 340), p(639, 479), p(0, 479)];
  assert.equal(detect(scene({background: 50, paper: 220, corners: floor})), null);
});

test('meldet nichts, wenn kein Blatt im Bild ist', () => {
  assert.equal(detect(scene({background: 100, paper: 100, corners: null})), null);
});

test('verwirft kleine Flächen', () => {
  const corners = [p(300, 220), p(360, 220), p(360, 270), p(300, 270)];
  assert.equal(detect(scene({background: 60, paper: 230, corners})), null);
});

function assertFound(image, expected, tolerance = TOLERANCE) {
  const found = detect(image);
  assert.ok(found, 'kein Blatt gefunden');
  found.forEach((corner, i) => {
    const off = Math.hypot(corner.x - expected[i].x, corner.y - expected[i].y);
    assert.ok(off <= tolerance, `Ecke ${i} liegt ${off.toFixed(1)} px daneben`);
  });
}

function detect(image) {
  try {
    return findDocumentQuad(cv, image);
  } finally {
    image.delete();
  }
}

function scene({background, paper, corners}) {
  const image = new cv.Mat(HEIGHT, WIDTH, cv.CV_8UC4, new cv.Scalar(background, background, background, 255));
  if (corners) fill(image, corners, paper);
  addNoise(image);
  cv.GaussianBlur(image, image, new cv.Size(3, 3), 0, 0, cv.BORDER_DEFAULT);
  return image;
}

function fill(image, corners, shade) {
  const polygon = cv.matFromArray(corners.length, 1, cv.CV_32SC2, corners.flatMap((c) => [c.x, c.y]));
  const polygons = new cv.MatVector();
  polygons.push_back(polygon);
  cv.fillPoly(image, polygons, new cv.Scalar(shade, shade, shade, 255));
  polygons.delete();
  polygon.delete();
}

// Fester Startwert: Rauschen wie bei einer Kamera, aber jeder Lauf gleich.
function addNoise(image) {
  let seed = 7;
  const data = image.data;
  for (let i = 0; i < data.length; i += 4) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    const delta = (seed % 25) - 12;
    for (let c = 0; c < 3; c++) data[i + c] = Math.max(0, Math.min(255, data[i + c] + delta));
  }
}

function p(x, y) {
  return {x, y};
}

"""Erzeugt den Referenzfall für PP-OCRv6 Small: synthetischer Beleg und Ergebnis von RapidOCR.

Einmalig ausführen (benötigt rapidocr und die Schrift Arial, nicht Teil der Runtime):
    python tests/fixtures/ocr/build_reference.py
Bild und JSON werden eingecheckt; der Test braucht nur onnxruntime und die Modelle unter models/.
RapidOCR rechnet mit denselben ONNX-Dateien, damit nur Vor- und Nachverarbeitung verglichen werden.
"""

import hashlib
import importlib.metadata
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
DETECTOR = ROOT / "models" / "pp-ocr-v6" / "detector"
RECOGNIZER = ROOT / "models" / "pp-ocr-v6" / "recognizer"
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"

# Ausgedacht, ohne personenbezogene Daten.
LINES = [
    "Bäckerei Müller GmbH",
    "Hauptstraße 12, 80331 München",
    "Datum: 26.10.2026 14:32",
    "2x Brötchen 1,20 €",
    "1x Kaffee groß 3,40 €",
    "Summe EUR 4,60",
    "MwSt 7% 0,30",
    "Vielen Dank!",
]


def receipt():
    font = ImageFont.truetype(FONT, 28)
    image = Image.new("RGB", (640, 60 + 52 * len(LINES)), "white")
    draw = ImageDraw.Draw(image)
    for index, line in enumerate(LINES):
        draw.text((40, 30 + 52 * index), line, font=font, fill="black")
    return image


def rapidocr_lines(path):
    from rapidocr import RapidOCR

    engine = RapidOCR(params={
        "Global.use_cls": False, "Global.log_level": "error",
        "Det.model_path": str(DETECTOR / "model.onnx"), "Rec.model_path": str(RECOGNIZER / "model.onnx"),
        "Rec.rec_keys_path": str(RECOGNIZER / "ppocrv6_dict.txt"),
    })
    result = engine(str(path))
    lines = []
    for box, text in zip(result.boxes, result.txts, strict=True):
        xs, ys = [float(point[0]) for point in box], [float(point[1]) for point in box]
        lines.append({"bounds": {"left": min(xs), "top": min(ys), "width": max(xs) - min(xs), "height": max(ys) - min(ys)}, "text": text})
    return sorted(lines, key=lambda line: line["bounds"]["top"])


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


if __name__ == "__main__":
    image_path = HERE / "receipt_de.png"
    receipt().save(image_path)
    reference = {
        "generator": f"rapidocr {importlib.metadata.version('rapidocr')}",
        "models": {"detector": sha256(DETECTOR / "model.onnx"), "recognizer": sha256(RECOGNIZER / "model.onnx")},
        "truth": LINES,
        "lines": rapidocr_lines(image_path),
    }
    (HERE / "pp_ocr_v6_reference.json").write_text(json.dumps(reference, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

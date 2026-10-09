"""Erzeugt kleine scikit-learn-Modelle als ONNX-Fixtures für die Tests des ML-Dienstes.

Einmalig ausführen (benötigt scikit-learn und skl2onnx, nicht Teil der Runtime):
    python tests/fixtures/sklearn/build_fixtures.py
Die erzeugten .onnx-Dateien werden eingecheckt; die Tests brauchen nur onnxruntime.
"""

from pathlib import Path

import numpy
from skl2onnx import to_onnx
from skl2onnx.common.data_types import FloatTensorType, StringTensorType
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

HERE = Path(__file__).resolve().parent


def classifier_with_text_classes():
    """Zwei Zahlen → Klasse "ja"/"nein"; Wahrscheinlichkeiten als ZipMap."""
    features = numpy.array([[0, 0], [0, 1], [1, 0], [1, 1], [2, 2], [3, 3]], dtype=numpy.float32)
    labels = numpy.array(["nein", "nein", "nein", "ja", "ja", "ja"])
    model = LogisticRegression().fit(features, labels)
    return to_onnx(model, features[:1], target_opset=15)


def regressor():
    """y = 2·a + 3·b + 1."""
    features = numpy.array([[0, 0], [1, 0], [0, 1], [2, 3]], dtype=numpy.float32)
    target = features @ numpy.array([2, 3], dtype=numpy.float32) + 1
    return to_onnx(LinearRegression().fit(features, target), features[:1], target_opset=15)


def pipeline_with_text_column():
    """Land (Text) und Umsatz (Zahl) → Klasse; String-Eingang, ohne ZipMap."""
    countries = numpy.array([["DE"], ["DE"], ["AT"], ["CH"], ["AT"], ["CH"]], dtype=object)
    revenue = numpy.array([[10], [20], [80], [90], [70], [85]], dtype=numpy.float32)
    labels = numpy.array([0, 0, 1, 1, 1, 1])
    pipeline = Pipeline([
        ("merkmale", ColumnTransformer([
            ("land", OneHotEncoder(handle_unknown="ignore"), [0]),
            ("umsatz", StandardScaler(), [1]),
        ])),
        ("modell", LogisticRegression()),
    ])
    pipeline.fit(numpy.hstack([countries, revenue]), labels)
    initial_types = [("land", StringTensorType([None, 1])), ("umsatz", FloatTensorType([None, 1]))]
    # ColumnTransformer erwartet eine Tabelle; skl2onnx verbindet die benannten Eingänge.
    return to_onnx(pipeline, initial_types=initial_types, target_opset=15, options={id(pipeline.steps[-1][1]): {"zipmap": False}})


if __name__ == "__main__":
    for name, build in [
        ("classifier_text_classes", classifier_with_text_classes),
        ("regressor", regressor),
        ("pipeline_text_column", pipeline_with_text_column),
    ]:
        (HERE / f"{name}.onnx").write_bytes(build().SerializeToString())
        print("geschrieben:", name)

"""Erzeugt ein kleines ONNX-Modell mit zwei Ausgängen wie RT-DETR/D-FINE für die Tests des ML-Dienstes.

Einmalig ausführen (benötigt das Paket onnx, nicht Teil der Runtime):
    python tests/fixtures/detectors/build_fixtures.py
Die erzeugte .onnx-Datei wird eingecheckt; die Tests brauchen nur onnxruntime.
"""

from pathlib import Path

import numpy
import onnx
from onnx import TensorProto, helper, numpy_helper

HERE = Path(__file__).resolve().parent

# Normierte Boxen (Mittelpunkt, Größe) und Klassen-Logits für drei Abfragen, zwei Klassen.
BOXES = numpy.array([[[0.5, 0.5, 0.2, 0.4], [0.25, 0.25, 0.1, 0.1], [0.8, 0.2, 0.2, 0.2]]], dtype=numpy.float32)
LOGITS = numpy.array([[[2.0, -1.0], [-3.0, -2.5], [-1.0, 1.5]]], dtype=numpy.float32)


def detr_like():
    """Eingang `images` [1, 3, 4, 4]; Ausgänge `pred_boxes` [1, 3, 4] und `logits` [1, 3, 2] (feste Werte)."""
    nodes = [
        helper.make_node("Constant", [], ["boxes_value"], value=numpy_helper.from_array(BOXES)),
        helper.make_node("Constant", [], ["logits_value"], value=numpy_helper.from_array(LOGITS)),
        helper.make_node("Identity", ["boxes_value"], ["pred_boxes"]),
        helper.make_node("Identity", ["logits_value"], ["logits"]),
    ]
    graph = helper.make_graph(
        nodes, "detr_like",
        [helper.make_tensor_value_info("images", TensorProto.FLOAT, [1, 3, 4, 4])],
        [helper.make_tensor_value_info("pred_boxes", TensorProto.FLOAT, [1, 3, 4]),
         helper.make_tensor_value_info("logits", TensorProto.FLOAT, [1, 3, 2])],
    )
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 15)])
    model.ir_version = 8
    onnx.checker.check_model(model)
    return model


if __name__ == "__main__":
    onnx.save(detr_like(), HERE / "detr_like.onnx")

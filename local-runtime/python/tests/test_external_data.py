import importlib.util
import tempfile
import unittest
from pathlib import Path

import numpy

from bundle_test_support import TENANT_A, FakeGlobalStore, UnlimitedQueue, bundle_file, payload_for
from novooa_bundles.bundle_store import BundleStore
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_ml.bundles.team_stores import TeamStores
from novooa_ml.model_requests import ModelService
from novooa_ml.session_cache import SessionCache
from novooa_ml.tensor_codec import decode_tensor, encode_tensor

HAS_ONNX = all(importlib.util.find_spec(name) is not None for name in ["onnx", "onnxruntime"])


@unittest.skipUnless(HAS_ONNX, "onnx und onnxruntime fehlen")
class ExternalDataModelTest(unittest.TestCase):
    def test_runs_a_model_whose_weights_live_next_to_it(self):
        import onnxruntime

        from novooa_ml.model_execution import session_factory

        contents = external_data_model()
        files = [
            bundle_file("model.onnx", contents["model.onnx"], "model-artifacts/m/versions/1/model.onnx"),
            bundle_file("weights.bin", contents["weights.bin"], "model-artifacts/m/versions/1/weights.bin"),
        ]
        root = Path(tempfile.mkdtemp())
        resolver = BundleResolver(BundleStore(root / "global"), FakeGlobalStore(contents), TeamStores(root / "teams"))
        service = ModelService(resolver, SessionCache(1024, session_factory(onnxruntime, 1)), numpy, UnlimitedQueue())
        payload = payload_for(files)
        service.load(TENANT_A, payload)

        response = service.execute(TENANT_A, {
            "modelKey": payload["modelKey"],
            "inputs": [encode_tensor("x", numpy.array([[1, 2, 3]], dtype=numpy.float32), numpy)],
            "outputs": [{"name": "y", "transformations": []}],
        })

        self.assertEqual(decode_tensor(response["outputs"][0], numpy).tolist(), [[11.0, 22.0, 33.0]])


def external_data_model():
    """Ein Add-Modell, dessen Gewichte als External Data in weights.bin liegen."""
    import onnx
    from onnx import TensorProto, helper, numpy_helper

    weights = numpy_helper.from_array(numpy.array([[10, 20, 30]], dtype=numpy.float32), name="w")
    graph = helper.make_graph(
        [helper.make_node("Add", ["x", "w"], ["y"])], "add",
        [helper.make_tensor_value_info("x", TensorProto.FLOAT, [1, 3])],
        [helper.make_tensor_value_info("y", TensorProto.FLOAT, [1, 3])],
        [weights],
    )
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 13)])
    model.ir_version = 8
    directory = Path(tempfile.mkdtemp())
    onnx.save_model(model, directory / "model.onnx", save_as_external_data=True, location="weights.bin", size_threshold=0)
    return {name: (directory / name).read_bytes() for name in ["model.onnx", "weights.bin"]}


if __name__ == "__main__":
    unittest.main()

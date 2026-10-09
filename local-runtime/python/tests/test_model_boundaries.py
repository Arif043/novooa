import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import base64

import numpy
from PIL import Image

from audio_fixtures import pcm16_wav, sine
from ml_test_support import decoded_tensor, png_base64
from novooa_ml.model_input.sources import initial_value
from novooa_ml.model_input.tensor_encoding import tensor_for_contract
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.transformations.values import AudioSignal


def definition(shape, data_type="float32"):
    return {"name": "eingabe", "dataType": data_type, "shape": shape}


class TensorEncodingTest(unittest.TestCase):
    def test_adds_the_batch_dimension_the_contract_expects(self):
        encoded = tensor_for_contract(numpy.zeros((3, 4)), definition(["dynamic", 3, 4]), numpy)

        self.assertEqual(encoded["shape"], [1, 3, 4])

    def test_accepts_dynamic_dimensions_and_converts_the_data_type(self):
        encoded = tensor_for_contract(numpy.array([1.7, 2.2]), definition(["dynamic"], "int64"), numpy)

        self.assertEqual(encoded["dataType"], "int64")
        self.assertEqual(decoded_tensor(encoded).tolist(), [1, 2])

    def test_names_input_and_shapes_when_the_contract_does_not_match(self):
        message = r"Eingang eingabe: Die Transformationen erzeugten die Form \[2, 3\], der Vertrag erwartet \[2, 4\]\."
        with self.assertRaisesRegex(ValueError, message):
            tensor_for_contract(numpy.zeros((2, 3)), definition([2, 4]), numpy)
        with self.assertRaisesRegex(ValueError, r"Form \[2, 3\], der Vertrag erwartet \[1, 1, 2, 3\]"):
            tensor_for_contract(numpy.zeros((2, 3)), definition([1, 1, 2, 3]), numpy)

    def test_rejects_an_unknown_data_type(self):
        with self.assertRaisesRegex(ValueError, "Nicht unterstützter Tensor-Datentyp: string"):
            tensor_for_contract(numpy.zeros(1), definition([1], "string"), numpy)

    def test_encodes_values_without_loss(self):
        values = numpy.array([[0.25, -1.5], [3.0, 4.75]], dtype=numpy.float32)

        encoded = tensor_for_contract(values.T, definition([2, 2]), numpy)

        numpy.testing.assert_array_equal(decoded_tensor(encoded), values.T)


class SourcesTest(unittest.TestCase):
    def test_passes_plain_values_through(self):
        for source_type, value in [("text", "Hallo"), ("number", 4.5), ("json", {"a": [1]}), ("boolean", False)]:
            with self.subTest(source_type=source_type):
                self.assertEqual(initial_value({"type": source_type, "value": value}, Image), value)

    def test_opens_images_and_decodes_audio(self):
        image = initial_value({"type": "image", "dataBase64": png_base64(Image.new("RGB", (3, 2)))}, Image)
        audio = initial_value({
            "type": "audio", "contentType": "audio/wav",
            "dataBase64": base64.b64encode(pcm16_wav(sine(440, 8000, 0.01), 8000)).decode(),
        }, Image)

        self.assertEqual(image.size, (3, 2))
        self.assertIsInstance(audio, AudioSignal)
        self.assertEqual((audio.samples.shape, audio.sample_rate), ((80, 1), 8000))

    def test_rejects_broken_base64(self):
        with self.assertRaises(ValueError):
            initial_value({"type": "image", "dataBase64": "kein base64!"}, Image)


class InputWorkerTest(unittest.TestCase):
    def payload(self, source, transformations, shape, data_type="float32"):
        steps = [{"type": kind, "parameters": parameters} for kind, parameters in transformations]
        return {"input": {**definition(shape, data_type), "transformations": steps}, "source": source}

    def test_runs_a_typical_image_classification_pipeline(self):
        source = {"type": "image", "dataBase64": png_base64(Image.new("RGB", (64, 32), (255, 0, 0)))}
        steps = [
            ("image.resize", {"width": 8, "height": 8}),
            ("tensor.scale", {"factor": 1 / 255}),
            ("tensor.layout", {"order": "channelsFirst"}),
            ("tensor.normalize", {"mean": [0.5, 0.5, 0.5], "std": [0.5, 0.5, 0.5]}),
        ]

        tensor = decoded_tensor(transform_payload(self.payload(source, steps, ["dynamic", 3, 8, 8]))["tensor"])

        self.assertEqual(tensor.shape, (1, 3, 8, 8))
        numpy.testing.assert_allclose(tensor[0, :, 0, 0], [1, -1, -1], atol=1e-5)

    def test_checks_the_chain_before_reading_the_source(self):
        source = {"type": "image", "dataBase64": "wird nie gelesen"}

        with self.assertRaisesRegex(ValueError, "Eingang eingabe: audio.mono erwartet audio, erhält image"):
            transform_payload(self.payload(source, [("audio.mono", {})], ["dynamic"]))


class OutputWorkerTest(unittest.TestCase):
    def test_returns_the_final_value_and_every_named_result(self):
        definitions = [{"name": "logits", "transformations": [
            {"type": "tensor.softmax", "parameters": {}, "result": "wahrscheinlichkeiten"},
            {"type": "tensor.argmax", "parameters": {}},
        ]}]

        [output] = transform_outputs(iter([("logits", numpy.array([[1.0, 3.0]]))]), definitions, numpy)

        values = output["transformationValues"]
        self.assertEqual(values["tensor"], [1])
        self.assertAlmostEqual(sum(values["wahrscheinlichkeiten"][0]), 1.0)
        self.assertEqual(output["tensor"].tolist(), [[1.0, 3.0]])

    def test_uses_the_count_bound_from_a_setting(self):
        # TypeScript hat `$anzahl` vor dem Aufruf bereits durch den Setting-Wert ersetzt.
        definitions = [{"name": "logits", "transformations": [{"type": "tensor.topK", "parameters": {"k": 2}}]}]

        [output] = transform_outputs([("logits", numpy.array([0.1, 0.7, 0.2]))], definitions, numpy)

        self.assertEqual([item["index"] for item in output["transformationValues"]["tensor"]], [1, 2])

    def test_checks_every_output_chain_first(self):
        definitions = [{"name": "maske", "transformations": [{"type": "geometry.mergeRows", "parameters": {}}]}]

        with self.assertRaisesRegex(ValueError, "Ausgang maske: geometry.mergeRows erwartet regions, erhält tensor"):
            transform_outputs([("maske", numpy.zeros((2, 2)))], definitions, numpy)


if __name__ == "__main__":
    unittest.main()

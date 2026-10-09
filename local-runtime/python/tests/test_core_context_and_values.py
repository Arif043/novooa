import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy
from PIL import Image

from ml_test_support import context
from novooa_ml.transformations.values import (
    AudioSignal,
    as_tensor,
    require_audio,
    require_image,
    require_text,
)


class ResourceAccessTest(unittest.TestCase):
    def test_reads_a_named_model_resource(self):
        ctx = context(resource_reader=lambda name: f"inhalt:{name}".encode())

        self.assertEqual(ctx.resource_bytes("labels.txt"), b"inhalt:labels.txt")

    def test_reports_missing_resource_access(self):
        with self.assertRaisesRegex(ValueError, "keinen Zugriff auf Modellressourcen"):
            context().resource_bytes("labels.txt")

    def test_rejects_an_invalid_resource_name(self):
        ctx = context(resource_reader=lambda name: b"")
        for name in ["", None, 3]:
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "Modellressource ist ungültig"):
                ctx.resource_bytes(name)

    def test_each_pipeline_starts_with_empty_metadata(self):
        first, second = context(), context()
        first.metadata["layout"] = "channelsFirst"

        self.assertEqual(second.metadata, {})


class ContextScopeTest(unittest.TestCase):
    def test_carries_no_user_values(self):
        # Einstellbare Werte bindet TypeScript als Settings vorab in die Parameter ein.
        self.assertFalse(hasattr(context(), "parameter_value"))


class AsTensorTest(unittest.TestCase):
    def test_passes_tensors_through_unchanged(self):
        tensor = numpy.arange(3)

        self.assertIs(as_tensor(tensor, context()), tensor)

    def test_gives_grayscale_images_a_channel_axis(self):
        self.assertEqual(as_tensor(Image.new("L", (4, 2)), context()).shape, (2, 4, 1))
        self.assertEqual(as_tensor(Image.new("RGB", (4, 2)), context()).shape, (2, 4, 3))

    def test_turns_audio_into_samples_or_channels_by_samples(self):
        mono = AudioSignal(numpy.zeros((5, 1), dtype=numpy.float32), 8000)
        stereo = AudioSignal(numpy.zeros((5, 2), dtype=numpy.float32), 8000)

        self.assertEqual(as_tensor(mono, context()).shape, (5,))
        self.assertEqual(as_tensor(stereo, context()).shape, (2, 5))

    def test_reports_values_that_never_became_a_tensor(self):
        with self.assertRaisesRegex(ValueError, "Texttransformation hat keinen Tensor erzeugt"):
            as_tensor("Hallo", context())
        with self.assertRaisesRegex(ValueError, "Transformation hat keinen Tensor erzeugt"):
            as_tensor({"a": 1}, context())


class RequireValueTest(unittest.TestCase):
    def test_accepts_matching_values(self):
        image = Image.new("RGB", (1, 1))
        signal = AudioSignal(numpy.zeros((1, 1)), 8000)

        self.assertIs(require_image(image, "image.test", context()), image)
        self.assertIs(require_audio(signal, "audio.test", context()), signal)
        self.assertEqual(require_text("Hallo", "text.test"), "Hallo")

    def test_rejects_media_steps_after_the_tensor(self):
        for check, kind in [(require_image, "image.test"), (require_audio, "audio.test")]:
            with self.subTest(kind=kind), self.assertRaisesRegex(ValueError, f"{kind} muss vor Tensortransformationen stehen"):
                check(numpy.zeros(1), kind, context())

    def test_names_the_expected_value(self):
        with self.assertRaisesRegex(ValueError, "image.test erwartet ein Bild"):
            require_image("kein Bild", "image.test", context())
        with self.assertRaisesRegex(ValueError, "audio.test erwartet Audio"):
            require_audio(Image.new("L", (1, 1)), "audio.test", context())
        with self.assertRaisesRegex(ValueError, "text.test erwartet Text"):
            require_text(42, "text.test")


if __name__ == "__main__":
    unittest.main()

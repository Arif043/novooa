import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy
from PIL import Image

from ml_test_support import png_base64, run
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.tensor_codec import decode_tensor
from novooa_ml.transformations.values import AudioSignal


def random_image(width, height):
    pixels = numpy.random.default_rng(7).integers(0, 256, size=(height, width, 3), dtype=numpy.uint8)
    return pixels, Image.fromarray(pixels, "RGB")


def tiled(image, size, overlap):
    payload = {
        "input": {"name": "bild", "dataType": "uint8", "shape": ["dynamic", size, size, 3], "transformations": [
            {"type": "image.decode", "parameters": {"colorSpace": "rgb"}},
            {"type": "image.tiles", "parameters": {"size": size, "overlap": overlap}},
        ]},
        "source": {"type": "image", "dataBase64": png_base64(image)},
    }
    encoded = transform_payload(payload)["tensor"]
    return decode_tensor(encoded, numpy), encoded["metadata"]


def untiled(model_output, metadata, **parameters):
    definitions = [{"name": "bild_aus", "transformations": [{"type": "tensor.untile", "parameters": {"input": "bild", **parameters}}]}]
    [output] = transform_outputs([("bild_aus", model_output)], definitions, numpy, input_metadata={"bild": metadata})
    return numpy.asarray(output["transformationValues"]["tensor"])


class TilesTest(unittest.TestCase):
    def test_tiles_and_untiles_back_to_the_exact_original(self):
        pixels, image = random_image(37, 23)

        tiles, metadata = tiled(image, 16, 4)

        self.assertEqual(tiles.shape, (2 * 3, 16, 16, 3))
        self.assertEqual(metadata["tiles"], {"rows": 2, "columns": 3, "size": 16, "overlap": 4, "width": 37, "height": 23})
        numpy.testing.assert_array_equal(untiled(tiles, metadata), pixels)

    def test_reassembles_an_upscaling_model_output(self):
        pixels, image = random_image(20, 11)
        tiles, metadata = tiled(image, 8, 2)
        upscaled = tiles.repeat(2, axis=1).repeat(2, axis=2)

        result = untiled(upscaled, metadata, scale=2)

        numpy.testing.assert_array_equal(result, pixels.repeat(2, axis=0).repeat(2, axis=1))

    def test_reads_channels_first_model_output(self):
        pixels, image = random_image(10, 10)
        tiles, metadata = tiled(image, 8, 0)

        result = untiled(numpy.moveaxis(tiles, -1, 1), metadata, layout="channelsFirst")

        numpy.testing.assert_array_equal(result, pixels)

    def test_a_small_image_is_one_padded_tile(self):
        _, image = random_image(5, 3)

        tiles, metadata = tiled(image, 8, 2)

        self.assertEqual(tiles.shape, (1, 8, 8, 3))
        self.assertEqual((metadata["tiles"]["rows"], metadata["tiles"]["columns"]), (1, 1))

    def test_rejects_tiles_that_do_not_match_the_grid_or_scale(self):
        _, image = random_image(20, 11)
        tiles, metadata = tiled(image, 8, 2)

        with self.assertRaisesRegex(ValueError, "Kacheln passen nicht zum Raster"):
            untiled(tiles[:-1], metadata)
        with self.assertRaisesRegex(ValueError, "passen nicht zu size × scale = 32"):
            untiled(tiles, metadata, scale=4)

    def test_rejects_an_overlap_as_large_as_the_tile(self):
        with self.assertRaisesRegex(ValueError, "0 ≤ overlap < size"):
            run(Image.new("RGB", (4, 4)), ("image.tiles", {"size": 4, "overlap": 4}))

    def test_untile_needs_the_grid_of_its_input(self):
        with self.assertRaisesRegex(ValueError, "kein Kachelraster"):
            untiled(numpy.zeros((1, 8, 8, 3)), {})


class AudioFramesTest(unittest.TestCase):
    signal = AudioSignal(numpy.arange(10, dtype=numpy.float32).reshape(-1, 1), 4)

    def test_cuts_windows_and_pads_the_last_one_with_silence(self):
        frames = run(self.signal, ("audio.frames", {"seconds": 1}))

        numpy.testing.assert_array_equal(frames, [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 0, 0]])

    def test_overlaps_windows_with_a_shorter_hop(self):
        frames = run(self.signal, ("audio.frames", {"seconds": 1, "hopSeconds": 0.5}))

        self.assertEqual(frames.shape, (4, 4))
        numpy.testing.assert_array_equal(frames[1], [2, 3, 4, 5])
        numpy.testing.assert_array_equal(frames[3], [6, 7, 8, 9])

    def test_a_short_signal_becomes_one_padded_window(self):
        frames = run(AudioSignal(numpy.ones((2, 1), dtype=numpy.float32), 4), ("audio.frames", {"seconds": 1}))

        numpy.testing.assert_array_equal(frames, [[1, 1, 0, 0]])

    def test_requires_mono_audio(self):
        with self.assertRaisesRegex(ValueError, "audio.mono"):
            run(AudioSignal(numpy.zeros((8, 2), dtype=numpy.float32), 4), ("audio.frames", {"seconds": 1}))


if __name__ == "__main__":
    unittest.main()

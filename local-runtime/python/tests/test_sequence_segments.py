import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.context import TransformationContext
from novooa_ml.model_output.worker import transformation_values


def segments(scores, **parameters):
    return transformation_values(default_transformation_registry(), 
        numpy.asarray(scores),
        [{"type": "sequence.segments", "parameters": {"frameDuration": 0.5, **parameters}, "result": "segments"}],
        TransformationContext(numpy),
    )["segments"]


class ScoreSegmentsTest(unittest.TestCase):
    def test_turns_frames_above_the_threshold_into_time_ranges(self):
        result = segments([0.1, 0.9, 0.8, 0.2, 0.7], threshold=0.5)

        self.assertEqual(result, [
            {"start": 0.5, "end": 1.5, "score": 0.85},
            {"start": 2.0, "end": 2.5, "score": 0.7},
        ])

    def test_merges_short_gaps_and_drops_short_segments(self):
        result = segments([0.9, 0.1, 0.9, 0.0, 0.0, 0.0, 0.9], threshold=0.5, mergeGap=0.5, minDuration=1.0)

        self.assertEqual(len(result), 1)
        self.assertEqual((result[0]["start"], result[0]["end"]), (0.0, 1.5))

    def test_accepts_a_frame_duration_from_hop_and_sample_rate(self):
        result = transformation_values(default_transformation_registry(), 
            numpy.array([0.0, 1.0]),
            [{"type": "sequence.segments", "parameters": {"hopLength": 160, "sampleRate": 16000}, "result": "s"}],
            TransformationContext(numpy),
        )["s"]

        self.assertEqual(result, [{"start": 0.01, "end": 0.02, "score": 1.0}])


class ClassSegmentsTest(unittest.TestCase):
    scores = [[0.9, 0.1, 0.0], [0.2, 0.7, 0.1], [0.1, 0.8, 0.1], [0.0, 0.1, 0.9]]

    def test_groups_consecutive_frames_of_the_same_class(self):
        result = segments(self.scores, labels=["stille", "sprecher-a", "sprecher-b"], backgroundIndex=0)

        self.assertEqual(result, [
            {"start": 0.5, "end": 1.5, "index": 1, "label": "sprecher-a", "score": 0.75},
            {"start": 1.5, "end": 2.0, "index": 2, "label": "sprecher-b", "score": 0.9},
        ])

    def test_keeps_every_class_without_background(self):
        self.assertEqual([item["index"] for item in segments(self.scores)], [0, 1, 2])

    def test_rejects_invalid_parameters(self):
        for parameters, message in [
            ({"frameDuration": 0}, "frameDuration"),
            ({"labels": ["nur-eins"]}, "labels"),
            ({"backgroundIndex": 5}, "backgroundIndex"),
        ]:
            with self.subTest(parameters=parameters), self.assertRaisesRegex(ValueError, message):
                segments(self.scores, **parameters)
        with self.assertRaisesRegex(ValueError, "sequence.segments"):
            segments(numpy.zeros((2, 2, 2)))


if __name__ == "__main__":
    unittest.main()

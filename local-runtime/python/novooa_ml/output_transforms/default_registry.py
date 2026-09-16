from .ctc import CtcGreedyDecodeStrategy
from .numeric import SigmoidStrategy, SoftmaxStrategy, ThresholdStrategy, TopKStrategy
from .registry import OutputTransformationRegistry
from .vision import ConnectedComponentsStrategy, NonMaximumSuppressionStrategy


def default_output_transformation_registry():
    return OutputTransformationRegistry(
        [
            SoftmaxStrategy(),
            SigmoidStrategy(),
            ThresholdStrategy(),
            TopKStrategy(),
            ConnectedComponentsStrategy(),
            NonMaximumSuppressionStrategy(),
            CtcGreedyDecodeStrategy(),
        ]
    )

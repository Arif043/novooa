from .ctc import CtcGreedyDecodeStrategy
from .numeric import SigmoidStrategy, SoftmaxStrategy, ThresholdStrategy, TopKStrategy
from .registry import OutputTransformationRegistry
from .vision import ConnectedComponentsStrategy, NonMaximumSuppressionStrategy
from .geometry import ScaleBoundsStrategy


def default_output_transformation_registry():
    return OutputTransformationRegistry(
        [
            SoftmaxStrategy(),
            SigmoidStrategy(),
            ThresholdStrategy(),
            TopKStrategy(),
            ConnectedComponentsStrategy(),
            ScaleBoundsStrategy(),
            NonMaximumSuppressionStrategy(),
            CtcGreedyDecodeStrategy(),
        ]
    )

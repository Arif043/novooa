from .ctc import CtcGreedyDecodeStrategy
from .numeric import SigmoidStrategy, SoftmaxStrategy, ThresholdStrategy, TopKStrategy
from .registry import OutputTransformationRegistry
from .vision import ConnectedComponentsStrategy, NonMaximumSuppressionStrategy
from .text_regions import TextRegionsStrategy
from .geometry import ScaleBoundsStrategy
from .row_grouping import MergeRowsStrategy


def default_output_transformation_registry():
    return OutputTransformationRegistry(
        [
            SoftmaxStrategy(),
            SigmoidStrategy(),
            ThresholdStrategy(),
            TopKStrategy(),
            ConnectedComponentsStrategy(),
            TextRegionsStrategy(),
            MergeRowsStrategy(),
            ScaleBoundsStrategy(),
            NonMaximumSuppressionStrategy(),
            CtcGreedyDecodeStrategy(),
        ]
    )

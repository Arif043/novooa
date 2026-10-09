from novooa_ml.transformations.kinds import AUDIO
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import AudioSignal, require_audio


class AudioMonoStrategy(TransformationStrategy):
    """Mischt alle Kanäle zu einem Kanal (Mittelwert)."""

    accepts = (AUDIO,)
    produces = AUDIO

    @property
    def transformation_type(self):
        return "audio.mono"

    def transform(self, value, parameters, context):
        signal = require_audio(value, self.transformation_type, context)
        samples = signal.samples.mean(axis=1, keepdims=True).astype(context.numpy.float32)
        return AudioSignal(samples, signal.sample_rate)

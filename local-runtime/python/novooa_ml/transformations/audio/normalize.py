from novooa_ml.transformations.kinds import AUDIO
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Choice, Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import AudioSignal, require_audio


class AudioNormalizeStrategy(TransformationStrategy):
    """Bringt die Lautstärke auf einen Spitzen- (`peak`) oder Effektivwert (`rms`)."""

    accepts = (AUDIO,)
    produces = AUDIO
    parameters = {"mode": Choice("peak", "rms", optional=True, default="peak"), "target": Number(minimum=0, optional=True)}

    @property
    def transformation_type(self):
        return "audio.normalize"

    def transform(self, value, parameters, context):
        signal = require_audio(value, self.transformation_type, context)
        numpy = context.numpy
        mode = parameters.get("mode", "peak")
        if mode not in ("peak", "rms"):
            raise ValueError("audio.normalize benötigt mode peak oder rms.")
        default = 1.0 if mode == "peak" else 0.1
        target = number(parameters.get("target", default), self.transformation_type, "target")
        samples = signal.samples
        level = numpy.abs(samples).max() if mode == "peak" else numpy.sqrt(numpy.mean(samples ** 2))
        # Stille hat keinen Pegel und bleibt unverändert.
        if level == 0:
            return signal
        return AudioSignal((samples * (target / level)).astype(numpy.float32), signal.sample_rate)

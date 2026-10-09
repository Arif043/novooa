from novooa_ml.transformations.kinds import AUDIO
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Choice, Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.tensor.fit_length import fit_length
from novooa_ml.transformations.values import AudioSignal, require_audio


class AudioFitDurationStrategy(TransformationStrategy):
    """Füllt mit Stille auf oder kürzt auf eine feste Dauer in Sekunden."""

    accepts = (AUDIO,)
    produces = AUDIO
    parameters = {"seconds": Number(minimum=0), "keep": Choice("start", "end", optional=True, default="start")}

    @property
    def transformation_type(self):
        return "audio.fitDuration"

    def transform(self, value, parameters, context):
        signal = require_audio(value, self.transformation_type, context)
        seconds = number(parameters.get("seconds"), self.transformation_type, "seconds")
        if seconds <= 0:
            raise ValueError("audio.fitDuration benötigt seconds größer als null.")
        length = max(1, round(seconds * signal.sample_rate))
        samples = fit_length(
            context.numpy, signal.samples,
            {"length": length, "axis": 0, "keep": parameters.get("keep", "start")},
        )
        return AudioSignal(samples, signal.sample_rate)

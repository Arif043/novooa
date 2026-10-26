from novooa_ml.transformations.kinds import AUDIO, TENSOR
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_audio


class AudioFramesStrategy(TransformationStrategy):
    """Zerlegt Mono-Audio in Fenster fester Dauer und rechnet sie als Batch `[N, Samples]`.

    Für Modelle mit fester Eingabelänge über längere Aufnahmen (Geräusch-, Sprecher- oder
    Aktivitätserkennung). Fenster `seconds`, Schritt `hopSeconds` (Standard: ohne Überlappung);
    das letzte Fenster wird mit Stille aufgefüllt. Ein Fenster je `hopSeconds` ab Sekunde 0.
    """

    accepts = (AUDIO,)
    produces = TENSOR
    parameters = {"seconds": Number(minimum=0), "hopSeconds": Number(minimum=0, optional=True)}

    @property
    def transformation_type(self):
        return "audio.frames"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        signal = require_audio(value, self.transformation_type, context)
        if signal.samples.shape[1] != 1:
            raise ValueError("audio.frames erwartet Mono-Audio; davor audio.mono einsetzen.")
        seconds = number(parameters.get("seconds"), self.transformation_type, "seconds")
        hop_seconds = number(parameters.get("hopSeconds", seconds), self.transformation_type, "hopSeconds")
        length, hop = round(seconds * signal.sample_rate), round(hop_seconds * signal.sample_rate)
        if length <= 0 or hop <= 0:
            raise ValueError("audio.frames benötigt seconds und hopSeconds von mindestens einem Sample.")
        samples = signal.samples[:, 0]
        count = 1 + max(0, -(-(samples.size - length) // hop))
        padded = numpy.zeros((count - 1) * hop + length, dtype=numpy.float32)
        padded[:samples.size] = samples
        return numpy.stack([padded[index * hop:index * hop + length] for index in range(count)])

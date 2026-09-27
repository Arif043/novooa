import base64
import io
import wave

from .registry import OutputTransformationStrategy


class WaveAudioStrategy(OutputTransformationStrategy):
    @property
    def transformation_type(self):
        return "audio.wav"

    def transform(self, value, parameters, context):
        sample_rate = parameters.get("sampleRate")
        if not isinstance(sample_rate, int) or sample_rate <= 0:
            raise ValueError("audio.wav benötigt eine positive sampleRate.")
        samples = context.numpy.asarray(value, dtype=context.numpy.float32).reshape(-1)
        pcm = context.numpy.clip(samples, -1, 1)
        pcm = (pcm * 32767).astype("<i2").tobytes()
        buffer = io.BytesIO()
        with wave.open(buffer, "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(sample_rate)
            wav.writeframes(pcm)
        return {
            "dataBase64": base64.b64encode(buffer.getvalue()).decode("ascii"),
            "contentType": "audio/wav",
            "fileName": parameters.get("fileName", "sprach-ausgabe.wav"),
        }

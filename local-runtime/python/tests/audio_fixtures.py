import base64
import io
import struct
import wave

import numpy


def sine(frequency, sample_rate, seconds, amplitude=0.5):
    times = numpy.arange(int(sample_rate * seconds)) / sample_rate
    return (amplitude * numpy.sin(2 * numpy.pi * frequency * times)).astype(numpy.float32)


def pcm16_wav(samples, sample_rate):
    """samples: (frames,) oder (frames, channels) im Bereich -1..1."""
    frames = numpy.atleast_2d(numpy.asarray(samples).T).T
    pcm = (numpy.clip(frames, -1, 1) * 32767).astype("<i2")
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as output:
        output.setnchannels(frames.shape[1])
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes(pcm.tobytes())
    return buffer.getvalue()


def riff_wav(data, sample_rate, channels, bits, format_tag, extensible=False):
    block_align = channels * bits // 8
    fmt = struct.pack(
        "<HHIIHH", 0xFFFE if extensible else format_tag, channels, sample_rate,
        sample_rate * block_align, block_align, bits,
    )
    if extensible:
        guid_tail = b"\x00\x00\x00\x00\x10\x00\x80\x00\x00\xaa\x00\x38\x9b\x71"
        fmt += struct.pack("<HHI", 22, bits, 0) + struct.pack("<H", format_tag) + guid_tail
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt + b"data" + struct.pack("<I", len(data)) + data
    return b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks


def audio_payload(wav_bytes, transformations, shape, content_type="audio/wav"):
    return {
        "input": {"name": "audio", "dataType": "float32", "shape": shape, "transformations": transformations},
        "source": {"type": "audio", "contentType": content_type, "dataBase64": base64.b64encode(wav_bytes).decode()},
    }


def dominant_frequency(samples, sample_rate):
    spectrum = numpy.abs(numpy.fft.rfft(samples))
    return numpy.fft.rfftfreq(len(samples), 1 / sample_rate)[int(numpy.argmax(spectrum))]

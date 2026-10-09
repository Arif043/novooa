"""Dekodiert WAV-Dateien ohne Zusatzbibliothek in float32-Samples im Bereich -1 bis 1."""

import struct

import numpy

WAV_CONTENT_TYPES = {"audio/wav", "audio/x-wav", "audio/wave", "audio/vnd.wave"}
PCM, IEEE_FLOAT, EXTENSIBLE = 1, 3, 0xFFFE


def decode_wav(data, content_type):
    """Liefert (samples, sampleRate); samples hat die Form (Frames, Kanäle)."""
    if content_type.split(";", 1)[0].strip().lower() not in WAV_CONTENT_TYPES:
        raise ValueError(
            f"Audio im Format {content_type} wird nicht unterstützt; die Runtime liest WAV-Dateien."
        )
    chunks = riff_chunks(data)
    if "fmt " not in chunks or "data" not in chunks:
        raise ValueError("Die WAV-Datei ist ungültig: fmt- oder data-Abschnitt fehlt.")
    format_tag, channels, sample_rate, bits = wav_format(chunks["fmt "])
    samples = samples_from(chunks["data"], format_tag, bits)
    frames = len(samples) // channels
    return samples[: frames * channels].reshape(frames, channels), sample_rate


def riff_chunks(data):
    if len(data) < 12 or data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError("Die WAV-Datei ist ungültig: RIFF/WAVE-Kopf fehlt.")
    chunks, offset = {}, 12
    while offset + 8 <= len(data):
        name = data[offset:offset + 4].decode("latin-1")
        size = struct.unpack_from("<I", data, offset + 4)[0]
        chunks.setdefault(name, data[offset + 8:offset + 8 + size])
        offset += 8 + size + (size % 2)
    return chunks


def wav_format(chunk):
    if len(chunk) < 16:
        raise ValueError("Die WAV-Datei ist ungültig: fmt-Abschnitt zu kurz.")
    format_tag, channels, sample_rate, _, _, bits = struct.unpack_from("<HHIIHH", chunk)
    if format_tag == EXTENSIBLE and len(chunk) >= 26:
        format_tag = struct.unpack_from("<H", chunk, 24)[0]
    if channels == 0 or sample_rate == 0:
        raise ValueError("Die WAV-Datei ist ungültig: Kanäle oder Abtastrate fehlen.")
    return format_tag, channels, sample_rate, bits


def samples_from(data, format_tag, bits):
    if format_tag == IEEE_FLOAT and bits in (32, 64):
        return numpy.frombuffer(data[: len(data) - len(data) % (bits // 8)], dtype=f"<f{bits // 8}").astype(numpy.float32)
    if format_tag != PCM or bits not in (8, 16, 24, 32):
        raise ValueError(f"WAV mit Format {format_tag} und {bits} Bit wird nicht unterstützt.")
    if bits == 8:
        return (numpy.frombuffer(data, dtype=numpy.uint8).astype(numpy.float32) - 128) / 128
    if bits == 24:
        raw = numpy.frombuffer(data[: len(data) - len(data) % 3], dtype=numpy.uint8).reshape(-1, 3)
        values = raw[:, 0].astype(numpy.int32) | (raw[:, 1].astype(numpy.int32) << 8) | (raw[:, 2].astype(numpy.int32) << 16)
        values = numpy.where(values >= 1 << 23, values - (1 << 24), values)
        return (values / float(1 << 23)).astype(numpy.float32)
    width = bits // 8
    values = numpy.frombuffer(data[: len(data) - len(data) % width], dtype=f"<i{width}")
    return (values / float(1 << (bits - 1))).astype(numpy.float32)

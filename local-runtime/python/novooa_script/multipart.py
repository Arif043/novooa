from email import policy
from email.parser import BytesParser


class MultipartError(ValueError):
    pass


def parse_multipart(content_type, body):
    """Zerlegt einen multipart/form-data-Körper in {Name: Bytes}.

    Die Dateien bleiben rohe Bytes: Es gibt keine Kodierung, die sie aufbläht.
    """
    if not content_type or not content_type.lower().startswith("multipart/form-data"):
        raise MultipartError("Erwartet wird multipart/form-data.")
    header = b"MIME-Version: 1.0\r\nContent-Type: " + content_type.encode("latin-1") + b"\r\n\r\n"
    message = BytesParser(policy=policy.HTTP).parsebytes(header + body)
    if not message.is_multipart():
        raise MultipartError("Der Körper ist kein gültiges Multipart.")
    parts = {}
    for part in message.iter_parts():
        name = part.get_param("name", header="content-disposition")
        if not name:
            raise MultipartError("Ein Teil hat keinen Namen.")
        parts[name] = part.get_payload(decode=True) or b""
    return parts

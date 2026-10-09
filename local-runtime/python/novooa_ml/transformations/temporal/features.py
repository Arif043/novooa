import math
from datetime import datetime, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from novooa_ml.transformations.kinds import DATETIME, TENSOR
from novooa_ml.transformations.schema import Boolean, Choice, ListOf, Text
from novooa_ml.transformations.strategy import TransformationStrategy

LINEAR = {
    "year": lambda moment: moment.year,
    "day": lambda moment: moment.day,
    "second": lambda moment: moment.second,
    "epochSeconds": lambda moment: moment.timestamp(),
}
# Periodische Merkmale mit ihrer Periode: zyklisch kodiert liegen Anfang und Ende nebeneinander.
PERIODIC = {
    "month": (lambda moment: moment.month, 12),
    "weekday": (lambda moment: moment.weekday(), 7),
    "hour": (lambda moment: moment.hour, 24),
    "minute": (lambda moment: moment.minute, 60),
    "dayOfYear": (lambda moment: moment.timetuple().tm_yday, 366),
}


class DatetimeFeaturesStrategy(TransformationStrategy):
    """Zerlegt einen Zeitpunkt in Zahlenmerkmale (Jahr, Monat, Wochentag, Stunde …).

    `weekday` zählt ab Montag = 0. Mit `cyclic: true` werden periodische Merkmale als
    sin/cos-Paar kodiert; `timeZone` wählt die Zeitzone, in der gezählt wird (Standard UTC).
    """

    accepts = (DATETIME,)
    produces = TENSOR
    parameters = {
        "features": ListOf(Choice("year", "month", "day", "weekday", "hour", "minute", "second", "dayOfYear", "epochSeconds")),
        "cyclic": Boolean(optional=True, default=False),
        "timeZone": Text(optional=True),
    }

    @property
    def transformation_type(self):
        return "datetime.features"

    def transform(self, value, parameters, context):
        if not isinstance(value, datetime):
            raise ValueError("datetime.features erwartet einen Zeitpunkt.")
        moment = value.astimezone(time_zone(parameters.get("timeZone")))
        cyclic = parameters.get("cyclic", False)
        if not isinstance(cyclic, bool):
            raise ValueError("datetime.features benötigt cyclic als Wahrheitswert.")
        encoded = [part for name in feature_names(parameters) for part in encoded_feature(moment, name, cyclic)]
        return context.numpy.asarray(encoded, dtype=context.numpy.float32)


def feature_names(parameters):
    names = parameters.get("features")
    if not isinstance(names, list) or not names:
        raise ValueError("datetime.features benötigt eine nicht leere Liste features.")
    for name in names:
        if name not in LINEAR and name not in PERIODIC:
            raise ValueError(f"datetime.features: Das unbekannte Merkmal {name} wird nicht unterstützt.")
    return names


def encoded_feature(moment, name, cyclic):
    if name in LINEAR:
        return [LINEAR[name](moment)]
    read, period = PERIODIC[name]
    value = read(moment)
    if not cyclic:
        return [value]
    angle = 2 * math.pi * value / period
    return [math.sin(angle), math.cos(angle)]


def time_zone(name):
    if name is None:
        return timezone.utc
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError, TypeError) as error:
        raise ValueError(f"datetime.features: Die Zeitzone {name} ist unbekannt.") from error

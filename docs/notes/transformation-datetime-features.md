# Transformation `datetime.features`

> Zerlegt einen Zeitpunkt in Zahlenmerkmale; `weekday` zählt ab Montag = 0.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `datetime` → `tensor`

Mit `cyclic: true` werden Monat, Wochentag, Stunde, Minute und Jahrestag als sin/cos-Paar kodiert, sodass z. B. 23 Uhr und 0 Uhr nah beieinander liegen. `timeZone` (IANA, z. B. `Europe/Berlin`) wählt die Zählzeitzone, Standard UTC.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `features` | Liste aus `year` oder `month` oder `day` oder `weekday` oder `hour` oder `minute` oder `second` oder `dayOfYear` oder `epochSeconds` | ja | – |
| `cyclic` | Wahrheitswert | nein | `false` |
| `timeZone` | Text | nein | – |

Hinweis: `features` (Liste aus `year`, `month`, `day`, `weekday`, `hour`, `minute`, `second`, `dayOfYear`, `epochSeconds`), optional `cyclic`, `timeZone`

## Fachliche Tests

- [`test_datetime_features.py`](../../local-runtime/python/tests/test_datetime_features.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Klassisches ML über ONNX](./klassisches-ml-onnx.md)

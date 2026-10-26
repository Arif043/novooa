# Transformation `resource.lookup`

> Ergänzt jeden Eintrag um seinen Namen aus einer Label-Datei des Modells (`artifactReference.resources`): eine Zeile je Label oder eine JSON-Liste.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `json-result` oder `detections` oder `keypoints` → Wertart der Eingabe

Große Label-Listen stehen so nicht im Manifest.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `resource` | Text | ja | – |
| `format` | `lines` oder `json` | nein | `"lines"` |
| `key` | Text | nein | `"index"` |
| `field` | Text | nein | `"label"` |

Hinweis: `resource`, optional `format` (`lines` oder `json`), `key` (Standard `index`), `field` (Standard `label`)

## Fachliche Tests

- [`test_detector_formats.py`](../../local-runtime/python/tests/test_detector_formats.py)
- [`test_resource_lookup.py`](../../local-runtime/python/tests/test_resource_lookup.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Workflow-Output-Mapping](./workflow-output-mapping.md)

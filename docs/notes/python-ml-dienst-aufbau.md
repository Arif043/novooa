# Aufbau des Python-ML-Dienstes

> Alle Transformationen bilden einen Katalog, geordnet nach Fachbereich mit einer Strategie je Datei; neue Strategien werden automatisch gefunden.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```text
local-runtime/python/
  novooa_bundles/                   Bündel: Schlüssel, Speicher, geprüfter Download (nur Stdlib)
  novooa_ml/
    transformations/                Katalog und Kern
      strategy.py registry.py context.py values.py parameters.py discovery.py
      kinds.py                      Wertarten
      pipeline_check.py             Prüfung der Wertarten-Kette (und Parameter beim Import)
      parameter_check.py, schema/   Parameterschemas und Prüfung
      image/ audio/ text/ data/ temporal/ tensor/ vision/ sequence/ resources/
    model_input/                    Quelle → Pipeline → Tensor (worker, sources, wav_decoder)
    model_output/                   Modellausgang → Pipeline → Ergebnisse (worker)
```

**Parameterschemas** aus `transformations/schema/`: `Integer`, `Number`,
`Boolean`, `Text`, `Choice`, `ListOf`, `Record` (feste Felder), `MapOf`,
`OneOf`.

```python
parameters = {
    "width": Integer(minimum=1),
    "height": Integer(minimum=1),
    "colorSpace": Choice("rgb", "rgba", "grayscale", optional=True),
}
```

**Regeln**

- Neue Strategie = nicht abstrakte Unterklasse von `TransformationStrategy`
  mit `accepts`/`produces` in einem Bereichsordner.
- `tests/test_transformation_architecture.py` sichert: eine Strategie je
  Datei, Ordner nach Bereich, Wertarten, Typ-Snapshot, jeder gelesene
  Parameter ist deklariert, und der
  [Transformationskatalog](./transformationskatalog.md) nennt jeden Typ mit
  allen Parametern.
- `tests/test_parameter_check.py` prüft alle mitgelieferten Manifeste
  (`local-runtime/system-models/` und `models/**/model.json`).
- `contract_validation_worker.py` und `onnx_validation_worker.py` sind die
  Prüfungen der [Veröffentlichung](./modelle-veroeffentlichen.md); sie laufen
  ohne ML-Dienst (`tests/test_validation_workers.py`).

## Siehe auch

- [Modellquellen im Worker](./modellquellen-im-worker.md)
- [Deklarative Transformationen](./transformationen-deklarativ.md)

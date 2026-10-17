# Drittanbieter-Code des Dokumentenscanners

Diese Dateien werden unverändert mitgeliefert und erst beim ersten Scan geladen
(kein CDN, keine Anfrage an fremde Server).

| Datei | Herkunft | Lizenz |
| --- | --- | --- |
| `jscanify.js` | [jscanify](https://github.com/puffinsoft/jscanify) 1.4.x (`src/jscanify.js`) | MIT, siehe `LICENSE-jscanify` |
| `opencv.js` | OpenCV.js-Build, die jscanify 1.4.x mitliefert (`src/opencv.js`); [OpenCV](https://opencv.org) | Apache License 2.0, https://opencv.org/license/ |

Die Version des enthaltenen OpenCV-Builds ist in der Datei selbst nicht
vermerkt; sie stammt aus dem npm-Paket `jscanify@1.4.3`.

`document_scanner_bridge.js` und `document_quad_detector.js` sind eigener Code von
novooa. jscanify wird nur noch zum Begradigen genutzt (`extractPaper`).

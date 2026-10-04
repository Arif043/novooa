# Feature: Dokumentenscanner

## Zweck

Beim Baustein „Bild anfordern“ (`mediaInput`) kann der Nutzer ein Dokument
scannen statt es nur zu fotografieren: Das Gerät erkennt die Ränder des Blatts,
begradigt es perspektivisch und liefert ein sauberes JPEG. Die Option heißt
`documentScanEnabled` (Schalter „Als Dokument scannen“ im Task-Builder, Standard
aus). Sie wirkt nur, wenn die Quelle „Kamera“ gewählt wird.

Das Ergebnis läuft wie jedes andere Bild durch den Dateispeicher. Backend und
Vertrag des Bausteins ändern sich dadurch nicht; das Backend reicht die Option
nur durch.

## Plattformen

| Plattform | Umsetzung | Erkennung |
| --- | --- | --- |
| Android | Plugin `cunning_document_scanner` (Google ML Kit) | im Plugin, mit eigener Oberfläche |
| iOS | Plugin `cunning_document_scanner` (VisionKit) | im Plugin, mit eigener Oberfläche |
| Web | eigener Scanner in `lib/features/document_scan/` | live im Kamerabild, siehe unten |
| macOS, Windows, Linux | kein Scanner | Schalter fehlt im Task-Builder, Aufnahme nutzt `image_picker` |

Die Entscheidung trifft `lib/core/platform/document_scan_support.dart`:
`nativeDocumentScanSupportedOnThisPlatform()` (Android, iOS),
`webDocumentScanSupportedOnThisPlatform()` (Browser) und
`documentScanSupportedOnThisPlatform()` für die Sichtbarkeit des Schalters.
Task-Builder und Aufnahme nutzen dieselbe Funktion, damit sie nie
auseinanderlaufen. Eine Aufgabe lässt sich auf einer Plattform bauen und auf einer
anderen ausführen: Der Browser scannt mit seinem Scanner, ein Handy mit dem
nativen.

## Ablauf im Browser

1. Der Dialog der Interaktion ruft `pickMediaSubmission` auf. Ist die Option an,
   die Quelle die Kamera und die Plattform der Browser, öffnet es `DocumentScanPage`
   als Vollbild-Seite (sonst läuft die Aufnahme über den `ActivityCubit` und das
   native Plugin).
2. Die Seite startet die Rückkamera (`getUserMedia`) und lädt beim ersten Mal die
   Erkennung nach.
3. Etwa fünfmal pro Sekunde sucht die Erkennung das Dokument im Kamerabild; die
   erkannte Kontur erscheint als farbiges Viereck über dem Bild.
4. „Aufnehmen“ nimmt ein Bild in voller Kameraauflösung auf und begradigt es entlang
   der erkannten Kontur. Wurde nichts erkannt, kommt das ganze Bild zurück.
5. Eine Vorschau zeigt das Ergebnis; „Wiederholen“ geht zurück zur Kamera,
   „Übernehmen“ gibt das JPEG an den Dialog zurück.

Die Seite hat vier Zustände: Kamera wird gestartet, Kamerabild mit Erkennung,
Vorschau und Fehler mit „Erneut versuchen“ und „Schließen“. Fehlermeldungen sind
deutsch: Kamerazugriff verweigert, keine Kamera oder keine sichere Verbindung,
Erkennung nicht ladbar, Aufnahme fehlgeschlagen.

## Aufbau

```text
lib/features/document_scan/
├── domain/
│   ├── entities/      ScanQuad, ScannedDocument, DocumentScanFailure
│   ├── repositories/  DocumentScanner, DocumentScanSession (Ports)
│   └── usecases/      OpenDocumentScanSession
├── infrastructure/    Web-Implementierung (Kamera, JS-Brücke); sonst Platzhalter
└── presentation/      DocumentScanCubit, DocumentScanPage, Widgets
web/document_scanner/  JS-Brücke und Bibliotheken (siehe unten)
```

- Die Domäne kennt weder Flutter noch den Browser. `DocumentScanner.open()` und
  `DocumentScanSession.capture()` liefern `Result<…, DocumentScanFailure>`
  (`multiple_result`), keine Exceptions.
- Die Infrastruktur wird per bedingtem Import gewählt
  (`document_scanner_platform.dart`): im Browser `WebDocumentScanner`, sonst ein
  Platzhalter, der `unsupported` meldet.
- Der Cubit hält die Sitzung, fragt die Erkennung nacheinander ab (nie zwei
  Abfragen gleichzeitig) und lässt die Kontur bei kurzen Aussetzern drei Bilder
  lang stehen, damit sie nicht flackert. Beim Schließen gibt er die Kamera frei,
  auch wenn sie sich gerade erst öffnet.
- Registrierung in beiden DI-Graphen (`service_locator.dart` und
  `standalone_dependency_configuration.dart`).

## Erkennung und mitgelieferter Code

Die Erkennung nutzt [jscanify](https://github.com/puffinsoft/jscanify) (MIT) auf
[OpenCV.js](https://opencv.org) (Apache-2.0). Beide liegen unverändert unter
`web/document_scanner/` und werden **nicht von einem CDN geladen**; die Herkunft
steht in `web/document_scanner/NOTICE.md`.

- `opencv.js` ist rund 9 MB groß. Es wird erst beim ersten Scan nachgeladen
  (`document_scanner_bridge.js` wird beim Start nur als kleines Skript
  eingebunden), die App startet also nicht langsamer. Das Laden dauert in einer
  lokalen Messung etwa 0,25 s; über das Netz entsprechend länger.
- Die Brücke (`document_scanner_bridge.js`) verkleinert das Bild für die Erkennung
  auf 480 px Breite (in der Messung dauerte die erste Erkennung bis zu 0,3 s, jede
  weitere rund 5 bis 20 ms),
  verwirft Erkennungen unter 15 % und über 97 % der Bildfläche und zieht die Ecken
  beim Begradigen um 0,6 % nach innen, damit kein Streifen vom Untergrund bleibt.
- Das Ergebnis ist ein JPEG mit Qualität 0,92; die längste Seite ist auf 2400 px
  begrenzt.

## Voraussetzungen und Grenzen

- Der Browser verlangt für die Kamera eine **sichere Verbindung** (`https` oder
  `localhost`). Auf `http` fehlt `navigator.mediaDevices`; der Scanner meldet dann,
  dass keine Kamera erreichbar ist und eine sichere Verbindung nötig ist.
- Es wird **eine Seite** gescannt; die Datei heißt immer `scan.jpg`.
- Die Erkennung braucht Kontrast zwischen Blatt und Untergrund. Weißes Papier auf
  weißem Tisch wird oft nicht erkannt; dann kommt das ganze Bild zurück. Die Ecken
  lassen sich nicht von Hand nachziehen.
- Die Erkennung sucht die größte Kante im Bild. Hat ein Dokument keinen klaren
  Rand oder liegt es teilweise außerhalb, kann die Kontur danebenliegen.
- Android und iOS: minSdk 24 mit `CAMERA`-Berechtigung, iOS 13.0 mit
  `NSCameraUsageDescription`. Das native Scannen hat nur eine Seite
  (`noOfPages: 1`). Schlägt es fehl, zeigt der Dialog die allgemeine Meldung „Bild
  konnte nicht ausgewählt werden.“

## Tests und Prüfung

- `test/features/document_scan/`: Cubit (Öffnen, Erkennung mit Aussetzern,
  Aufnahme, Wiederholen, Fehler, Freigabe der Kamera, Schließen während des
  Öffnens) und Oberfläche (alle Zustände, 48-px-Touch-Ziel, Übernehmen gibt das
  Dokument zurück, große Schrift auf kleinem Fenster).
- `test/core/platform/document_scan_support_test.dart`: Plattformerkennung.
- Nicht automatisiert: das Zusammenspiel mit der echten Kamera. Es wurde einmalig
  von Hand in Chrome geprüft, mit Testkamera (`--use-fake-device-for-media-stream`
  und einem Video eines schräg liegenden Blatts): Erkennung auf etwa 0,6 % der
  Bildgröße genau, Aufnahme, Vorschau, Übernehmen, verweigerte Berechtigung, keine
  Kamera, unsichere Seite. Nicht geprüft sind echte Handys und andere Browser
  (Safari, Firefox).

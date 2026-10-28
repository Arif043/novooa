# Datei-Detailansicht

> Die Detailseite zeigt den Inhalt der gewählten Version in einer Karte, daneben einen Inspektor mit Verlauf und Details; alle Dateiaktionen sitzen in der Kopfzeile.

Gehört zu: [Dateien](../index/dateien.md)

Code: `lib/features/files/presentation/pages/file_detail_page.dart`,
Widgets unter `presentation/widgets/detail/`.

- **Layout** im [Luminous-Seitenstil](./luminous-seitenstil.md): Kopfzeile mit
  Zurück, Dateiart, Name und einer Zeile „Tabelle · 8 KB · geändert vor
  5 Min. · in Rechnungen“. Ab 840 px Breite stehen Inhalt (70 %) und
  Inspektor (30 %) nebeneinander, darunter scrollt die Seite und der
  Inspektor folgt dem Inhalt.
- **Aktionen:** Umbenennen, Herunterladen, Bild bearbeiten (PNG/JPEG) und
  Kopieren als Symbolknöpfe; Verschieben, Neue Version hochladen und Löschen
  im Menü. Unter 600 px Breite liegt alles im Menü. Semantik der Aktionen
  steht in [Dateiaktionen](./datei-aktionen.md).
- **Inspektor**, Reiter **Versionen**: neueste zuerst, „Aktuell“ an der
  `currentVersionId` (nicht an der Auswahl), Zeitpunkt relativ und absolut,
  Größe samt Änderung zur Vorversion. Je Version Herunterladen, ältere
  zusätzlich Wiederherstellen. Reiter **Details**: Typ, Format, Größe,
  Verzeichnis, erstellt, geändert, Anzahl Versionen von höchstens N
  ([Versionsrotation](./datei-versionsrotation.md)).
- **Alte Version ansehen:** Ein Hinweis über dem Inhalt bietet
  „Wiederherstellen“ und „Zur aktuellen Version“. Wer den aktuellen Stand
  ansieht, folgt neuen Versionen automatisch, auch aus Aufgaben; eine bewusst
  gewählte alte Version bleibt stehen.
- **Inhalt:** Text und JSON sind bearbeitbar („Neue Version sichern“);
  `.xlsx` schreibgeschützt als Tabelle mit Blattauswahl (`package:excel`),
  Fettschrift bleibt, E-Mail-Adressen und URLs sind Links; PDF mit
  `package:pdfx` samt Seitennavigation und Zoom; Bilder mit Zoom. Ohne
  Vorschau bietet die Karte Herunterladen an.
- **Bildeditor:** `pro_image_editor` im Vollbild mit Zuschneiden/Drehen,
  Anpassen, Filter, Zeichnen, Text und Weichzeichnen; Farben aus dem
  App-Theme (Adapter auf `material_ui`), Kerntexte übersetzt. „Fertig“ legt
  eine neue Version im Format der Datei an (PNG bleibt PNG, JPEG bleibt
  JPEG); andere Bildtypen und ältere Versionen sind nicht bearbeitbar.
- **Zustände:** Die Seite beobachtet die Datei selbst — Umbenennen und
  Verschieben erscheinen sofort, wird sie anderswo gelöscht, schließt die
  Seite. Laden und Fehler (mit „Erneut versuchen“) gibt es für die Seite und
  für den Inhalt einer Version getrennt.
- Vorhandene Versionen werden nie verändert; Speichern erzeugt immer eine
  neue ([Copy-on-Write](./datei-copy-on-write.md)).

## Siehe auch

- [Dateiaktionen](./datei-aktionen.md)
- [Dateien-Seite](./dateien-seite.md)

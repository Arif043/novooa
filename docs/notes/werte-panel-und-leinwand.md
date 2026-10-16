# Werte im Panel und auf der Leinwand

> Das rechte Panel zeigt alle Werte eines Bausteins zum Umbenennen, Kopieren und Anheften; die `#`-Suche bietet alle erreichbaren Werte als Template-Label an.

Gehört zu: [Aufgabe](../index/aufgabe.md)

**Panel** (`NodeOutputChips`):

- Antippen benennt um (belegte Namen bekommen eine Nummer).
- Kopier-Symbol kopiert `{{Name}}`.
- Pin-Symbol (`OutputCanvasToggle`) legt fest, ob der Wert als Chip auf der
  Leinwand steht (`showOnCanvas`, Standard: Hauptwert und Felder).
- Auf der Leinwand lassen sich sichtbare Werte per Doppelklick umbenennen.

**Template-Eingaben:** Template-fähige Texteingaben zeigen Ausdrücke als
Labels. `#` öffnet eine Suche nach Werten und statisch erkennbaren
Script-Variablen aus dem erreichbaren Vorgängerpfad. Gespeichert bleibt der
Ausdruck `{{name}}`; die Label-Darstellung ist reine UI.

Einzige Quelle, welche Werte ein Baustein-Typ hat:
`domain/entities/workflow_node_outputs.dart` — für Panel und `#`-Suche.

## Siehe auch

- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
- [Registrierte Executor-Outputs](./executor-outputs.md)

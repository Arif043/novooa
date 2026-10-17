# Flacher Namensraum der Werte

> Alle Werte eines Graphen stehen in einem einzigen, graph-weit eindeutigen Namensraum und werden nur über explizite Templates wie `{{Kunde}}` eingebunden.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Jeder Baustein speichert `outputs: [{key, name, showOnCanvas}]`
  (`WorkflowOutput`). `key` ist der technische Schlüssel (`value`, `found` …),
  `name` der Name in Templates (`{{Datensatz}}`, `{{Gefunden}}`).
- Backend: `flatOutputsFor` in `template-expression-resolver.ts`.
- Kanten liefern **keine** Werte. Ein Knoten bekommt nichts von seinen
  Vorgängern, außer über Templates.
- Ein Wert ohne Eintrag in `outputs` ist nicht erreichbar; die Knoten-ID ist
  kein Ersatzname. `{{Datensatz.found}}` gibt es nicht. Ein Punkt-Pfad führt
  nur in den JSON-Inhalt eines Werts (`{{antwort.name}}`, `{{kunde.name}}`).
- Felder (strukturierte Prompt-Ausgabe, Dialogeingabe, Script mit
  `workflow_output`): Schlüssel = Feldname, Name startet gleich, ist
  umbenennbar und graph-weit eindeutig („Antwort“, „Antwort2“); Feldnamen
  müssen nur im Baustein eindeutig sein. Einen Gesamtwert gibt es nicht.
  Ein geänderter Feldname ergibt einen neuen Schlüssel.
- Namen vergibt der Builder lokalisiert, großgeschrieben, ab 2 nummeriert.
  `showOnCanvas`: Hauptwert und Felder an, übrige aus.
- „Für jedes Element“ liefert je Runde ein flaches Objekt der Unterplan-Werte;
  in Zweigen und Schleifen sind äußere Werte unter denselben Namen und als
  `{{global.Name}}` erreichbar.
- Eine alleinstehende Variable übergibt ihren Rohwert, keine Textdarstellung.

## Siehe auch

- [Ergebnisvertrag eines Bausteins](./node-ergebnisvertrag.md)
- [Werte im Panel und auf der Leinwand](./werte-panel-und-leinwand.md)

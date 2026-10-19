# Wissensgraph

> Die Graph-Ansicht zeigt Notizen als Knoten in einer Live-Kraftsimulation auf einem ruhigen Verlauf: Notizen stoßen sich ab, Links ziehen wie Federn, beim Ziehen reagiert der ganze Graph.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

- Kanten aus `outgoingLinks` (ohne Richtung, Duplikate und Selbstlinks);
  Klick auf einen Knoten wählt die Notiz im Editor.
- **Simulation** (`KnowledgeGraphSimulation`, Kräfte in
  `KnowledgeGraphForces`, nach d3-force):
  - Abstoßung zwischen allen Knoten (bis 520 px Reichweite), Link-Federn mit
    Ruhelänge 120 px (Stärke nach Grad, Knotenpunkte bleiben ruhig),
    leichte Schwerkraft zur Mitte, Kollision gegen überlappende Labels.
  - Temperatur `alpha` startet bei 1 und kühlt in rund 300 Schritten ab; feste
    Zeitschritte von 1/60 s (`KnowledgeGraphSimulationTicker`), danach hält
    der Ticker an.
  - Beim Öffnen startet der Graph nach Höhe angeordnet
    (`KnowledgeGraphLayers`): Je mehr Notizen eine Notiz über ihre
    ausgehenden Links direkt und indirekt erreicht (ohne Ebenen- und
    Mengengrenze), desto weiter oben steht sie. Gleich viele bilden eine
    Reihe, zu breite Reihen brechen um. Danach bewegt die Simulation die
    Knoten frei. Neue Notizen starten neben einem verlinkten Nachbarn und
    heizen kurz auf.
  - Ziehen fixiert den Knoten und hält die Simulation warm (`alphaTarget`
    0.3): Nachbarn folgen, der Rest weicht aus. Losgelassen ist der Knoten
    wieder frei und findet seinen Platz selbst.
  - „Zurücksetzen“ setzt die Ansicht zurück und startet wieder aus der
    Anordnung nach Höhe.
- **Darstellung:** radialer Verlauf aus den Flächenfarben mit zartem
  Akzent-Schimmer in der Mitte und leichter Vignette
  (`KnowledgeGraphBackground`, Farben aus dem Theme). Knotengröße nach Zahl
  der Links.
- **Prompt-Kontext:** Ist eine Notiz gewählt, leuchten genau die Notizen, die
  ein Prompt mit dieser Notiz als Anhang sieht: sie selbst, ihre ausgehenden
  Links direkt (kräftig) und indirekt (schwächer), samt der Links zwischen
  ihnen. Backlinks und alles jenseits von 5 Ebenen bzw. 50 Notizen treten
  zurück. Die Leiste nennt die Zahl („n Notizen im Prompt-Kontext“).
  Berechnet von `KnowledgeNoteReach` mit denselben Regeln wie beim Run
  ([Wissensnotizen als Anhang](./wissensnotizen-als-anhang.md)).
- Reduzierte Bewegung: Die Simulation rechnet sofort bis zur Ruhe, ohne
  Animation.

## Siehe auch

- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md)
- [Wissensbasis-Seite](./wissensbasis-seite.md)

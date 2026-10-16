# Anschlüsse auf der Leinwand

> Jeder offene Pfad endet mit „Baustein hier verbinden“; Bedingungen und Schleifen haben zusätzlich einen Anschluss für die Fortsetzung danach.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- „Baustein hier verbinden“ steht am Ende jedes Pfads, auch wenn er schon
  Bausteine enthält.
- Unter allen Zweigen einer Bedingung steht „Nach der Bedingung“ für den
  übergeordneten Pfad; Schleifen bieten „Nach der Schleife“. Gestrichelte
  Rückführungen und eine Trennlinie kennzeichnen die Fortsetzung.
- Diese Anschlüsse sind reine Darstellung, keine gespeicherten Bausteine.
- Pfade behalten ihre eigene Spalte bis zum letzten Anschluss; ungleich lange
  Zweige werden nicht zeilenweise neu zentriert.
- `WorkflowCanvasOptions.showReturnEdges` steuert die Rückführungspfeile
  (Standard `false`); Layout und Ausführung hängen nicht davon ab.
- `TaskBuilderCubit.addConnectedNode` verbindet einen neuen Baustein mit
  `afterId` im Hauptgraphen oder mit `ownerId`/`branchId` im Unterplan;
  `channelKind` erhält die Kanalwahl auch im Unterplan.

## Siehe auch

- [Layout des Aufgabenstudios](./aufgabenstudio-layout.md)
- [Baustein „Für jedes Element“](./foreach-baustein.md)

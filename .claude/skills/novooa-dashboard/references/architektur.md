# Architektur eines Dashboards

Dashboards folgen denselben Regeln wie das offizielle Frontend, nur kleiner.

## Ordner je Feature

```
lib/features/<feature>/
├── domain/            # reines Dart: keine Flutter-, HTTP- oder Paket-Importe
│   ├── entities/      # unveränderlich, Equatable, Werte-Typen statt Strings
│   ├── repositories/  # Schnittstellen
│   └── usecases/      # je ein Ablauf, `call()`
├── infrastructure/    # Runtime-Adapter: WorkspaceApiClient, Echtzeit, Mapper
└── presentation/
    ├── cubits/        # sealed States
    ├── pages/
    └── widgets/       # eine Verantwortung je Widget, eigene Klasse statt build*()
```

- **Domain** kennt `novooa_runtime_client` nicht. Nur `infrastructure/`
  importiert das Paket.
- **Kennungen** als Werte-Typen (`extension type const TaskId(String value)`
  in `lib/shared/domain/ids.dart`), nicht als lose Strings.
- **Ergebnisse** schreibender Abläufe als `Result<T, Failure>`
  (`multiple_result`); Variablen heißen nach dem Erfolgsfall
  (`runIdOrFailure`), nie `result`.
- **Abhängigkeiten** per Konstruktor; verdrahtet wird nur in
  `app/dashboard_dependencies.dart` (`GetIt.asNewInstance()`, pro Anmeldung
  neu). Keine Singletons in Features.
- Höchstens 200 Zeilen je Datei, 20 je Funktion.

## Die vier Zustände

Jede Ansicht mit Daten aus der Runtime zeigt alle vier:

| Zustand | Vorlage |
| --- | --- |
| Laden | `LoadingView` |
| Fehler | `FailureView(message, onRetry)` mit „Erneut versuchen“ |
| Leer | `EmptyView(message, actionLabel, onAction)` mit hilfreicher Aktion |
| Erfolg | die eigentliche Liste |

```dart
BlocBuilder<RunsCubit, RunsState>(
  builder: (context, state) => switch (state) {
    RunsLoading() => const LoadingView(),
    RunsFailure() => FailureView(
      message: DashboardKeys.loadFailed.tr(),
      onRetry: context.read<RunsCubit>().load,
    ),
    RunsLoaded(:final runs) when runs.isEmpty => EmptyView(...),
    RunsLoaded(:final runs) => _RunList(runs: runs),
  },
);
```

## Neues Feature anlegen (Rezept)

1. Entität und Repository-Schnittstelle in `domain/`.
2. Use Case(s), die nur die Schnittstelle kennen.
3. Adapter in `infrastructure/` gegen [die Runtime-API](runtime-api.md),
   lesend über `watchWorkspaceChannel` ([Echtzeit](echtzeit.md)).
4. Registrierung in `DashboardDependencies._register`.
5. Cubit(s) im `DashboardShell` bereitstellen, Seite in
   `DashboardNavigation` aufnehmen.
6. Texte in `assets/translations/{en,de,tr}.json` und `DashboardKeys`.
7. Cubit-Test je Mutation (Muster: `test/runs_cubit_test.dart` mit Fakes aus
   `test/fakes.dart`).

## Oberfläche

- **Theme:** Farben, Typografie und Formen nur aus `Theme.of(context)`;
  Kundenfarbe in `DashboardTheme._seed`. Abstände aus `Spacing` (8er-Raster).
- **Mobil zuerst:** Listen scrollen, Inhalte höchstens
  `Spacing.contentMaxWidth` breit, Navigation unten unter 840 px, seitlich
  darüber. Keine festen Breiten oder Höhen für Bildschirme.
- **Bedienbarkeit:** Touch-Ziele mindestens 48 × 48, Icons mit `tooltip` oder
  `semanticLabel`, Texte skalierbar (kein `maxLines` ohne `overflow`).
- **Wenige Entscheidungen:** eine Hauptaktion je Karte („Starten“,
  „Freigeben“); seltene Aktionen in Details.
- **Sprache:** Englisch ist Standard und Rückfall; `de` und `tr` ergänzen.
  Domänenbegriffe wie im offiziellen Frontend: Aufgabe, Lauf, Freigabe,
  Auslöser (en: task, run, approval, trigger).

## Tests

- Cubits mit Fakes der Repository-Schnittstellen, `pumpEventQueue()` nach
  Stream-Ereignissen, `close()` am Ende jedes Tests.
- Mapper mit echten JSON-Beispielen aus [der Runtime-API](runtime-api.md),
  auch mit fehlenden Feldern und unbekannten Status.
- Widget-Tests für Formulare, wenn sie Eingaben umwandeln.

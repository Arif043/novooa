# Architektur von Import/Export

> Jeder Bereich ist eine Strategie hinter dem Port `TransferSection`; drei Use Cases exportieren, prüfen und importieren.

Gehört zu: [Import/Export](../index/import-export.md)

- **Backend** (`functions/src/features/workspace_transfer/`):
  `TransferSection` je Bereich (Strategy), Use Cases `ExportWorkspace`,
  `InspectWorkspaceImport`, `ImportWorkspace`; ZIP-Adapter auf `fflate`.
- **Client** (`lib/features/workspace_transfer/`): `WorkspaceExportCubit`,
  `WorkspaceImportCubit`; Dateidialoge über `TransferFileGateway`
  (file_picker); Binärübertragung über `WorkspaceBinaryClient`. Export
  speichert über den Speichern-Dialog, im Web als Browser-Download.
- Ein neuer Bereich ist eine neue `TransferSection` (OCP).

Offen: Der Client hält Export und Import vollständig im Speicher; sehr große
Dateibestände bräuchten Streaming im Client.

## Siehe auch

- [Ablauf und Garantien von Import/Export](./transfer-ablauf.md)

import 'package:flutter/material.dart';

import '../../domain/entities/connection.dart';

/// Auswahl einer gespeicherten Verbindung für einen Baustein. Eine gelöschte
/// Verbindung bleibt sichtbar, statt den Baustein stillschweigend auf „keine“
/// zu setzen. Ohne [noneLabel] muss eine Verbindung gewählt werden.
class ConnectionPickerField extends StatelessWidget {
  const ConnectionPickerField({
    super.key,
    required this.selectedId,
    required this.connections,
    required this.onChanged,
    this.noneLabel,
    this.helperText,
  });

  final String selectedId;
  final List<Connection> connections;
  final ValueChanged<String> onChanged;

  /// Beschriftung der Auswahl „keine Verbindung“; `null` blendet sie aus.
  final String? noneLabel;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final known = connections.any((connection) => connection.id == selectedId);
    final missing = selectedId.isNotEmpty && !known;
    return DropdownButtonFormField<String>(
      key: ValueKey('connection-picker-$selectedId-${connections.length}'),
      initialValue: selectedId.isEmpty && noneLabel == null ? null : selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Verbindung',
        helperText: helperText,
        helperMaxLines: 2,
      ),
      items: [
        if (noneLabel != null)
          DropdownMenuItem(value: '', child: Text(noneLabel!)),
        for (final connection in connections)
          DropdownMenuItem(value: connection.id, child: Text(connection.name)),
        if (missing)
          DropdownMenuItem(
            value: selectedId,
            child: const Text('Verbindung nicht gefunden'),
          ),
      ],
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
    );
  }
}

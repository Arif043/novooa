import 'package:equatable/equatable.dart';

/// Ein benannter Ausgabewert eines Bausteins.
///
/// [key] ist der technische Schlüssel des Executors (`value` für den
/// Hauptwert, sonst z.B. `found`, siehe `outputKeysOf`); [name] der
/// graph-weit eindeutige Name, unter dem Vorlagen ihn nutzen (`{{Gefunden}}`).
/// [showOnCanvas] entscheidet, ob der Wert als Chip auf der Leinwand steht.
class WorkflowOutput extends Equatable {
  const WorkflowOutput({
    required this.key,
    required this.name,
    this.showOnCanvas = false,
  });

  /// Der Hauptwert, sichtbar auf der Leinwand.
  const WorkflowOutput.primary(this.name)
    : key = primaryOutputKey,
      showOnCanvas = true;

  static const primaryOutputKey = 'value';

  final String key;
  final String name;
  final bool showOnCanvas;

  bool get isPrimary => key == primaryOutputKey;

  WorkflowOutput copyWith({String? name, bool? showOnCanvas}) {
    return WorkflowOutput(
      key: key,
      name: name ?? this.name,
      showOnCanvas: showOnCanvas ?? this.showOnCanvas,
    );
  }

  @override
  List<Object?> get props => [key, name, showOnCanvas];
}

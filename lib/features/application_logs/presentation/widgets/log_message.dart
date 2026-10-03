import 'package:flutter/material.dart';
import 'package:syscat2/core/widgets/console_output_block.dart';

import '../../domain/entities/application_log.dart';
import '../../domain/entities/script_log_events.dart';

/// Der Haupttext eines Protokolleintrags. Ausgabe eines Scripts steht in Festbreitenschrift auf
/// eigener Fläche; die Fehlerausgabe (stderr) ist rötlich, falls es sie gibt.
class LogMessage extends StatelessWidget {
  const LogMessage({super.key, required this.log});

  final ApplicationLog log;

  @override
  Widget build(BuildContext context) {
    final text = log.message ?? log.event;
    return switch (log.event) {
      scriptStderrLogEvent => ConsoleOutputBlock(text: text, isError: true),
      scriptStdoutLogEvent => ConsoleOutputBlock(text: text),
      _ => Text(text, style: Theme.of(context).textTheme.titleSmall),
    };
  }
}

import 'package:flutter/widgets.dart';

/// Rendert den Text einer Agenten-Antwort; ein Bereich kann so eigene
/// Darstellungen einhängen (etwa Links auf Notizen), ohne das Panel zu ändern.
typedef AssistantMessageBodyBuilder =
    Widget Function(BuildContext context, String text);

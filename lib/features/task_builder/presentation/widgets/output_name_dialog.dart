import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Fragt einen neuen Namen für einen Ausgabewert ab — für den Hauptwert
/// ([NodeOutputNameField]) wie für die weiteren Werte im Panel
/// ([NodeOutputChips]). Gibt `null` zurück, wenn abgebrochen wurde.
///
/// Besitzt seinen [TextEditingController] selbst (statt ihn von außen zu
/// bekommen) und gibt ihn erst in seinem eigenen `dispose()` frei — der
/// Cupertino-Dialog animiert beim Schließen, das `TextField` bleibt also
/// noch kurz gemountet, nachdem `Navigator.pop()` zurückkehrt. Ein von außen
/// direkt danach disposter Controller führt dort zu „used after being
/// disposed". Gleiches Muster wie `RenameTaskDialog`.
class OutputNameDialog extends StatefulWidget {
  const OutputNameDialog({super.key, required this.initialValue});

  final String initialValue;

  @override
  State<OutputNameDialog> createState() => _OutputNameDialogState();
}

class _OutputNameDialogState extends State<OutputNameDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(LocaleKeys.ui_ausgabename.tr()),
      content: TextField(
        controller: _controller,
        autofocus: true,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        ],
        decoration: InputDecoration(
          hintText: LocaleKeys.ui_hint_output_name.tr(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(LocaleKeys.ui_speichern.tr()),
        ),
      ],
    );
  }
}

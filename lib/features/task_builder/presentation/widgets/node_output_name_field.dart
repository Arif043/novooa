import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_node_outputs.dart';
import '../../domain/entities/workflow_output_types.dart';
import '../cubits/task_builder_cubit.dart';
import 'node_output_type_style.dart';

/// Zeigt und bearbeitet den fachlichen Ausgabenamen eines Bausteins mit
/// genau einem Output — direkt als Template-Ausdruck nutzbar (`{{name}}`).
///
/// Bausteine mit mehreren fachlichen Outputs (strukturierte Prompt-Ausgabe,
/// Dialogeingabe) haben keinen eigenen Ausgabenamen; dort vergibt der Nutzer
/// stattdessen für jedes Feld einen eigenen Namen (siehe die jeweiligen
/// Feld-Editoren), weshalb dieses Widget sich dafür ausblendet.
class NodeOutputNameField extends StatelessWidget {
  const NodeOutputNameField({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    if (hasFlatOutputFields(node.config)) {
      return const SizedBox.shrink();
    }
    final outputName = node.outputName.trim();
    if (outputName.isEmpty) return const SizedBox.shrink();
    final style = NodeOutputTypeStyle.of(primaryOutputTypeOf(node.config));
    return Tooltip(
      message: LocaleKeys.ui_edit_output_name_typed.tr(
        namedArgs: {'type': style.label},
      ),
      child: InputChip(
        avatar: Icon(style.icon, size: AppSpacing.md, color: Colors.white),
        label: Text(outputName),
        backgroundColor: style.color,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        onPressed: () => _showEditor(context),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context) async {
    final outputName = await showIosDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _OutputNameDialog(initialValue: node.outputName),
    );
    if (!context.mounted || outputName == null) return;
    context.read<TaskBuilderCubit>().updateNodeOutputName(node.id, outputName);
  }
}

/// Besitzt seinen [TextEditingController] selbst (statt ihn von außen zu
/// bekommen) und gibt ihn erst in seinem eigenen `dispose()` frei — der
/// Cupertino-Dialog animiert beim Schließen, das `TextField` bleibt also
/// noch kurz gemountet, nachdem `Navigator.pop()` zurückkehrt. Ein von außen
/// direkt danach disposter Controller führt dort zu „used after being
/// disposed". Gleiches Muster wie `RenameTaskDialog`.
class _OutputNameDialog extends StatefulWidget {
  const _OutputNameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_OutputNameDialog> createState() => _OutputNameDialogState();
}

class _OutputNameDialogState extends State<_OutputNameDialog> {
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

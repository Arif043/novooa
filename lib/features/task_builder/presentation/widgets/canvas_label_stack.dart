import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../cubits/task_builder_cubit.dart';
import 'node_output_type_style.dart';
import 'workflow_canvas_layout.dart';

/// Die Chips eines Pfeils als zentrierte, vertikale Reihe — üblicherweise
/// genau einer (Bedingungs-Label oder Ausgabename), bei mehreren
/// fachlichen Ausgabewerten (z.B. strukturierte Prompt-Ausgabe) aber
/// mehrere untereinander.
class CanvasLabelStack extends StatelessWidget {
  const CanvasLabelStack({super.key, required this.link});

  final CanvasLink link;

  @override
  Widget build(BuildContext context) {
    final background = link.isCondition
        ? Colors.grey[600] ?? Colors.grey
        : Theme.of(context).colorScheme.primaryContainer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < link.labels.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _CanvasLabelChip(label: link.labels[i], background: background),
        ],
      ],
    );
  }
}

/// Ein einzelner Label-Chip. Ohne [CanvasLabel.editTarget] (strukturelle
/// Labels wie "Für jedes Element") reiner Text ohne Geste. Mit Edit-Ziel:
/// Doppelklick macht den Text direkt inline editierbar (voll selektiert,
/// bereit zum Überschreiben) — bewusst kein Dialog, die Änderung wird bei
/// Enter/Fokusverlust sofort fachlich übernommen (siehe [_submit]).
class _CanvasLabelChip extends StatefulWidget {
  const _CanvasLabelChip({required this.label, required this.background});

  final CanvasLabel label;
  final Color background;

  @override
  State<_CanvasLabelChip> createState() => _CanvasLabelChipState();
}

class _CanvasLabelChipState extends State<_CanvasLabelChip> {
  TextEditingController? _controller;
  FocusNode? _focusNode;

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.label.editTarget == null) return;
    final controller = TextEditingController(text: widget.label.text);
    final focusNode = FocusNode();
    setState(() {
      _controller = controller;
      _focusNode = focusNode;
    });
    // Erst nach dem Aufbau des Textfelds fokussieren/selektieren — sonst
    // existiert der EditableText-State noch nicht.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  void _submit(BuildContext context) {
    final controller = _controller;
    final target = widget.label.editTarget;
    if (controller == null) return;
    final value = controller.text.trim();
    setState(() {
      _controller = null;
      _focusNode = null;
    });
    controller.dispose();
    if (target == null || value.isEmpty || value == widget.label.text) return;
    _applyEdit(context, target, value);
  }

  void _applyEdit(
    BuildContext context,
    CanvasLabelEditTarget target,
    String value,
  ) {
    final cubit = context.read<TaskBuilderCubit>();
    switch (target) {
      case OutputEditTarget(:final nodeId, :final key):
        cubit.renameOutput(nodeId: nodeId, key: key, name: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final editable = widget.label.editTarget != null;
    final editing = _controller != null;
    final labelType = widget.label.type;
    final typeStyle = labelType == null
        ? null
        : NodeOutputTypeStyle.of(labelType);
    // Begrenzt, damit lange Bedingungstexte benachbarte Zweige nicht
    // überdecken; der volle Text steht im Tooltip.
    final chip = Container(
      constraints: const BoxConstraints(minWidth: 32, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeStyle?.color ?? widget.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _withTypeIcon(
        typeStyle,
        editing
            ? IntrinsicWidth(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: textStyle,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: .new(color: SyscatTheme.primaryOrange),
                    ),
                  ),
                  onSubmitted: (_) => _submit(context),
                  onTapOutside: (_) => _submit(context),
                ),
              )
            : Tooltip(
                message: widget.label.text,
                child: Text(
                  widget.label.text,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
    if (!editable) return _typeSemantics(typeStyle, chip);
    return Semantics(
      button: true,
      label:
          'Label "${widget.label.text}"${_typeSuffix(typeStyle)} bearbeiten, Doppelklick',
      child: GestureDetector(onDoubleTap: _startEditing, child: chip),
    );
  }

  Widget _withTypeIcon(NodeOutputTypeStyle? style, Widget content) {
    if (style == null) return content;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(style.icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(child: content),
      ],
    );
  }

  Widget _typeSemantics(NodeOutputTypeStyle? style, Widget chip) {
    if (style == null) return chip;
    return Semantics(
      label: '${widget.label.text}${_typeSuffix(style)}',
      child: chip,
    );
  }

  String _typeSuffix(NodeOutputTypeStyle? style) =>
      style == null ? '' : ' (${style.label})';
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class PromptChoiceField extends StatelessWidget {
  const PromptChoiceField({
    super.key,
    required this.controller,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final TextEditingController controller;
  final int index;
  final bool canRemove;
  final void Function(int index, String value) onChanged;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Antwort ${index + 1}',
          suffixIcon: canRemove
              ? IconButton(
                  icon: const Icon(CupertinoIcons.delete),
                  onPressed: () => onRemove(index),
                )
              : null,
        ),
        onChanged: (value) => onChanged(index, value),
      ),
    );
  }
}

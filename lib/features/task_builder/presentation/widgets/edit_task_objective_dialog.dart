import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class EditTaskObjectiveDialog extends StatefulWidget {
  const EditTaskObjectiveDialog({super.key, required this.initialObjective});

  final String initialObjective;

  @override
  State<EditTaskObjectiveDialog> createState() =>
      _EditTaskObjectiveDialogState();
}

class _EditTaskObjectiveDialogState extends State<EditTaskObjectiveDialog> {
  static const double _maxDialogWidth = 520;

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialObjective);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final paddedWidth = constraints.maxWidth - AppSpacing.lg * 2;
        final dialogColor = colorScheme.brightness == Brightness.dark
            ? const Color(0xFF151515)
            : colorScheme.surface;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: paddedWidth < _maxDialogWidth
                    ? paddedWidth
                    : _maxDialogWidth,
              ),
              child: CupertinoPopupSurface(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dialogColor,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogContent(controller: _controller),
                      Container(
                        height: 1,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      _DialogActions(
                        onCancel: () => Navigator.of(context).pop(),
                        onSave: () =>
                            Navigator.of(context).pop(_controller.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final titleStyle = CupertinoTheme.of(
      context,
    ).textTheme.navTitleTextStyle.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Text('Notiz bearbeiten', style: titleStyle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Halte fest, worauf diese Aufgabe hinarbeiten soll.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ObjectiveTextField(controller: controller),
        ],
      ),
    );
  }
}

class _ObjectiveTextField extends StatelessWidget {
  const _ObjectiveTextField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      autofocus: true,
      minLines: 5,
      maxLines: 8,
      padding: const EdgeInsets.all(AppSpacing.md),
      placeholder: 'Ziel oder Notiz zur Aufgabe',
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _DialogAction(
              label: 'Abbrechen',
              isDestructive: true,
              onPressed: onCancel,
            ),
          ),
          Container(
            width: 1,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          Expanded(
            child: _DialogAction(
              label: 'Speichern',
              onPressed: onSave,
              isDefault: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });

  final String label;
  final bool isDestructive;
  final VoidCallback onPressed;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isDefault ? FontWeight.w600 : FontWeight.w400,
          color: isDestructive ? ColorScheme.of(context).error : null,
        ),
      ),
    );
  }
}

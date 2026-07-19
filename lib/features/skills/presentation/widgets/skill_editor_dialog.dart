import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_draft.dart';

/// Dialog zum Erstellen und Bearbeiten von Fähigkeiten. Gibt beim Speichern
/// den entsprechenden [SkillDraft] via [Navigator.pop] zurück.
class SkillEditorDialog extends StatefulWidget {
  const SkillEditorDialog({super.key, this.initial});

  final Skill? initial;

  @override
  State<SkillEditorDialog> createState() => _SkillEditorDialogState();
}

class _SkillEditorDialogState extends State<SkillEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
    _contentController = TextEditingController(
      text: widget.initial?.content ?? _defaultContent,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Fähigkeit bearbeiten' : 'Fähigkeit anlegen'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z. B. E-Mails freundlich beantworten',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Kurzbeschreibung',
                  hintText: 'Wann soll diese Fähigkeit eingesetzt werden?',
                ),
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'SKILL.md',
                  hintText:
                      'Anleitung in Markdown — was das Modell tun soll, wenn '
                      'diese Fähigkeit geladen wird.',
                  alignLabelWithHint: true,
                ),
                minLines: 10,
                maxLines: 20,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Speichern' : 'Anlegen'),
        ),
      ],
    );
  }

  void _submit() {
    final draft = SkillDraft(
      title: _titleController.text,
      description: _descriptionController.text,
      content: _contentController.text,
    );
    Navigator.of(context).pop(draft);
  }

  static const _defaultContent = '''---
name: neue-fähigkeit
description: Kurzbeschreibung, wann diese Fähigkeit eingesetzt wird.
---

# Neue Fähigkeit

Beschreibe hier, was das Modell tun soll, wenn diese Fähigkeit aktiviert wird.
''';
}

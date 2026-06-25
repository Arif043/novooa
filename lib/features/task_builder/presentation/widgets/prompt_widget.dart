import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

class PromptWidget extends StatefulWidget {
  const PromptWidget({super.key});

  @override
  State<PromptWidget> createState() => _PromptWidgetState();
}

class _PromptWidgetState extends State<PromptWidget> {

  var selectedOutput = OutputType.text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: .all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: .circular(AppSpacing.xl),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text("Prompt", style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          TextField(decoration: InputDecoration(hintText: 'Hier kommt die Anweisung'),),
          const SizedBox(height: AppSpacing.md,),
          Text('Ausgabe', style: SyscatTheme.taskBody,),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<OutputType>(
            segments: [
              ButtonSegment<OutputType>(
                value: OutputType.text,
                label: Text('Freitext'),
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment<OutputType>(
                value: OutputType.enum_,
                label: Text('Entscheidung'),
                icon: Icon(Icons.list),
              ),
            ],
            selected: {selectedOutput},
            onSelectionChanged: (value) {
              setState(() {
                selectedOutput = value.first;
              });
            },
          ),
          if (selectedOutput == OutputType.enum_)
            ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Mögliche Antworten', style: SyscatTheme.taskBodySmall,),
              const SizedBox(height: AppSpacing.xs),
              TextField(decoration: InputDecoration(hintText: 'Hier kommt die erste Antwort'),),
              TextField(decoration: InputDecoration(hintText: 'Hier kommt die zweite Antwort'),),
              
            ]
        ],
      ),
    );
  }
}

enum OutputType {
  text,
  enum_
}
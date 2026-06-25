import 'package:flutter/material.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: .circular(999),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: .circular(999),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.format_align_left),
              tooltip: "Prompt hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.call_split),
              tooltip: "Verzweigung hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.auto_awesome),
              tooltip: "Verfeinerung hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.face),
              tooltip: "Menschliche Aktion hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.code),
              tooltip: "Menschliche Aktion hinzufügen",
            ),
          ],
        ),

      ),
    );
  }
}

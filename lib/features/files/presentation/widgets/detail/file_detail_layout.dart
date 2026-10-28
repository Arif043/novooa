import 'package:flutter/material.dart';

import '../../../../../core/layout/page_insets.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../cubits/file_detail_state.dart';
import 'file_content_card.dart';
import 'file_detail_commands.dart';
import 'file_detail_header.dart';
import 'file_inspector.dart';

/// Ab Tablet-Breite Inhalt und Inspektor nebeneinander; auf dem Handy
/// scrollt die Seite und der Inspektor folgt unter dem Inhalt.
class FileDetailLayout extends StatelessWidget {
  const FileDetailLayout({super.key, required this.state});

  static const _sideBySideMinWidth = 840.0;
  static const _compactHeaderMaxWidth = 600.0;

  final FileDetailReady state;

  @override
  Widget build(BuildContext context) {
    final commands = FileDetailCommands(context, state);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = PageInsets.forWidth(constraints.maxWidth).gutter;
        final header = FileDetailHeader(
          state: state,
          commands: commands,
          compact: constraints.maxWidth < _compactHeaderMaxWidth,
        );
        final content = FileContentCard(state: state, commands: commands);
        final inspector = FileInspector(state: state, commands: commands);
        final padding = EdgeInsets.fromLTRB(
          gutter,
          AppSpacing.lg,
          gutter,
          gutter,
        );
        return constraints.maxWidth >= _sideBySideMinWidth
            ? _SideBySide(padding, header, content, inspector)
            : _Stacked(
                padding,
                constraints.maxHeight,
                header,
                content,
                inspector,
              );
      },
    );
  }
}

class _SideBySide extends StatelessWidget {
  const _SideBySide(this.padding, this.header, this.content, this.inspector);

  final EdgeInsets padding;
  final Widget header;
  final Widget content;
  final Widget inspector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          header,
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: content),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 3, child: inspector),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stacked extends StatelessWidget {
  const _Stacked(
    this.padding,
    this.viewportHeight,
    this.header,
    this.content,
    this.inspector,
  );

  final EdgeInsets padding;
  final double viewportHeight;
  final Widget header;
  final Widget content;
  final Widget inspector;

  @override
  Widget build(BuildContext context) {
    // Inhalt und Inspektor brauchen eine feste Höhe (Tabellen, Reiter);
    // sie richtet sich nach dem sichtbaren Bereich, nicht nach Pixeln.
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: [
          header,
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: viewportHeight * 0.7, child: content),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: viewportHeight * 0.6, child: inspector),
        ],
      ),
    );
  }
}

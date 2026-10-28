import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/widgets/luminous_card.dart';
import '../../cubits/file_detail_state.dart';
import 'file_detail_commands.dart';
import 'file_details_panel.dart';
import 'file_version_list.dart';

/// Rechte Spalte (bzw. unten auf dem Handy): Reiter „Versionen“ und
/// „Details“. Versionen zuerst, weil sie die häufigere Frage beantworten.
class FileInspector extends StatelessWidget {
  const FileInspector({super.key, required this.state, required this.commands});

  final FileDetailReady state;
  final FileDetailCommands commands;

  @override
  Widget build(BuildContext context) {
    return LuminousCard(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(
                  text:
                      '${LocaleKeys.files_tab_versions.tr()} '
                      '(${state.versions.length})',
                ),
                Tab(text: LocaleKeys.files_tab_details.tr()),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FileVersionList(state: state, commands: commands),
                  FileDetailsPanel(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

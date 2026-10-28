import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../files/domain/usecases/find_team_file.dart';
import '../../../../files/presentation/pages/file_detail_page.dart';
import '../../../../teams/domain/usecases/get_current_team_id.dart';
import '../../../domain/entities/run_effect.dart';

/// Öffnet die Datei einer Folge; gibt es sie nicht mehr, sagt ein Hinweis das.
Future<void> openEffectFile(
  BuildContext context,
  FileWrittenEffect effect,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final teamId = await serviceLocator<GetCurrentTeamId>()();
  final file = await serviceLocator<FindTeamFile>()(teamId, effect.fileId);
  if (file == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(LocaleKeys.run_effects_file_missing.tr())),
    );
    return;
  }
  await navigator.push(FileDetailPage.route(file));
}

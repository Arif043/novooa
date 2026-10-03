import 'package:syscat2/core/runtime/employees_availability.dart';
import 'package:syscat2/core/runtime/skills_availability.dart';
import 'package:flutter/cupertino.dart';

import '../../features/assistant/domain/entities/assistant_context.dart';
import '../../root_tab.dart';

List<RootTab> rootTabs({required bool isStandalone}) => [
  RootTab(
    title: 'Aufgaben',
    icon: CupertinoIcons.rectangle_3_offgrid,
    path: '/tasks',
  ),
  RootTab(title: 'Zeitplan', icon: CupertinoIcons.calendar, path: '/schedule'),
  if (isStandalone)
    RootTab(title: 'Datenbank', icon: CupertinoIcons.table, path: '/database'),
  RootTab(title: 'Dateien', icon: CupertinoIcons.folder, path: '/files'),
  RootTab(
    title: 'Wissensbasis',
    icon: CupertinoIcons.book,
    path: '/knowledge-base',
  ),
  if (skillsAvailable())
    RootTab(
      title: 'Fähigkeiten',
      icon: CupertinoIcons.sparkles,
      path: '/skills',
    ),
  if (employeesAvailable())
    RootTab(
      title: 'Mitarbeiter',
      icon: CupertinoIcons.person_2_square_stack,
      path: '/employees',
    ),
  RootTab(
    title: 'Aktivitäten',
    icon: CupertinoIcons.rectangle_grid_1x2,
    path: '/activity',
  ),
  RootTab(title: 'Einstellungen', icon: CupertinoIcons.gear, path: '/settings'),
];

AssistantContext? assistantContextForRootTab({
  required RootTab selectedTab,
  required String location,
  required bool isStandalone,
}) {
  if (isStandalone) return null;
  final area = switch (selectedTab.path) {
    '/tasks' => AssistantArea.taskBuilder,
    '/knowledge-base' => AssistantArea.knowledgeBase,
    _ => null,
  };
  return area == null ? null : AssistantContext(area: area, route: location);
}

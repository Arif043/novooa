import 'package:flutter/cupertino.dart';

import '../../root_tab.dart';

List<RootTab> rootTabs() => [
  RootTab(
    title: 'Aufgaben',
    icon: CupertinoIcons.rectangle_3_offgrid,
    path: '/tasks',
  ),
  RootTab(
    title: 'Zeitplan',
    icon: CupertinoIcons.calendar,
    path: '/schedule',
    hasPageHeader: true,
  ),
  RootTab(title: 'Datenbank', icon: CupertinoIcons.table, path: '/database'),
  RootTab(
    title: 'Dateien',
    icon: CupertinoIcons.folder,
    path: '/files',
    hasPageHeader: true,
  ),
  RootTab(
    title: 'Wissensbasis',
    icon: CupertinoIcons.book,
    path: '/knowledge-base',
  ),
  RootTab(
    title: 'Fähigkeiten',
    icon: CupertinoIcons.sparkles,
    path: '/skills',
    hasPageHeader: true,
  ),
  RootTab(
    title: 'Mitarbeiter',
    icon: CupertinoIcons.person_2_square_stack,
    path: '/employees',
    hasPageHeader: true,
  ),
  RootTab(
    title: 'Aktivitäten',
    icon: CupertinoIcons.rectangle_grid_1x2,
    path: '/activity',
  ),
  RootTab(title: 'Einstellungen', icon: CupertinoIcons.gear, path: '/settings'),
];

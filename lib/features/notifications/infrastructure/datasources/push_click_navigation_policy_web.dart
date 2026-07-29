import 'package:web/web.dart' as web;

bool shouldNavigateFromPushClick() {
  return !web.window
      .matchMedia('(min-width: 900px) and (hover: hover) and (pointer: fine)')
      .matches;
}

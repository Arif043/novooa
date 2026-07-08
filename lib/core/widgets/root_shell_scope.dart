import 'package:flutter/material.dart';

class RootShellController extends ChangeNotifier {
  Widget? _title;
  bool _isDisposed = false;

  Widget? get title => _title;

  void setTitle(Widget? title) {
    if (_isDisposed) return;
    _title = title;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class RootShellScope extends InheritedNotifier<RootShellController> {
  const RootShellScope({
    super.key,
    required RootShellController controller,
    required super.child,
  }) : super(notifier: controller);

  static RootShellController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RootShellScope>();
    assert(scope != null, 'RootShellScope fehlt im Widget-Baum.');
    return scope!.notifier!;
  }
}

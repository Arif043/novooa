import 'dart:async';

import 'package:flutter/material.dart';

class OfflineStatusSnackbar extends StatefulWidget {
  const OfflineStatusSnackbar({
    required this.isOnline,
    required this.scaffoldMessengerKey,
    required this.child,
    super.key,
  });

  final Stream<bool> isOnline;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  State<OfflineStatusSnackbar> createState() => _OfflineStatusSnackbarState();
}

class _OfflineStatusSnackbarState extends State<OfflineStatusSnackbar> {
  StreamSubscription<bool>? _subscription;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBar;
  var _isOnline = true;

  @override
  void initState() {
    super.initState();
    _subscription = widget.isOnline.listen(_updateNetworkStatus);
  }

  void _updateNetworkStatus(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline) {
      _snackBar?.close();
      _snackBar = null;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOfflineStatus());
  }

  void _showOfflineStatus() {
    if (!mounted || _isOnline || _snackBar != null) return;
    final messenger = widget.scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    _snackBar = messenger.showSnackBar(_offlineSnackBar());
    _snackBar!.closed.then((_) {
      _snackBar = null;
      if (!_isOnline) _showOfflineStatus();
    });
  }

  SnackBar _offlineSnackBar() {
    return const SnackBar(
      content: Text('Keine Internetverbindung'),
      duration: Duration(days: 365),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

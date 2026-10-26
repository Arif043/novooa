import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_failure.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:syscat2/features/plugins/domain/usecases/set_plugin_enabled.dart';
import 'package:syscat2/features/plugins/domain/usecases/watch_plugins.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';

/// Plugins im Speicher: Schalten wirkt sofort, Fehler lassen sich vorgeben.
class FakePluginRepository implements PluginRepository {
  FakePluginRepository([Set<String> enabled = const {}])
    : _enabled = {...enabled};

  final Set<String> _enabled;
  final _changes = StreamController<List<PluginActivation>>.broadcast();
  PluginFailure? failNextSwitch;
  Object? loadError;

  List<PluginActivation> get _current => [
    for (final id in _enabled)
      PluginActivation(id: PluginId(id), isEnabled: true),
  ];

  @override
  Stream<List<PluginActivation>> watchPlugins() async* {
    final error = loadError;
    if (error != null) throw error;
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<Result<PluginActivation, PluginFailure>> setEnabled(
    PluginId id, {
    required bool enabled,
  }) async {
    final failure = failNextSwitch;
    if (failure != null) {
      failNextSwitch = null;
      return Error(failure);
    }
    enabled ? _enabled.add(id.value) : _enabled.remove(id.value);
    _changes.add(_current);
    return Success(PluginActivation(id: id, isEnabled: enabled));
  }
}

PluginsCubit pluginsCubitWith(FakePluginRepository repository) =>
    PluginsCubit(WatchPlugins(repository), SetPluginEnabled(repository))
      ..start();

/// Stellt einen [PluginsCubit] bereit, wie `main.dart` es app-weit tut.
Widget withPlugins(Widget child, {Set<String> enabled = const {}}) =>
    BlocProvider(
      create: (_) => pluginsCubitWith(FakePluginRepository(enabled)),
      child: child,
    );

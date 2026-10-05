import 'package:bloc/bloc.dart';

import '../../domain/usecases/plugin_use_cases.dart';
import 'plugin_catalog_state.dart';

/// Der Katalog der vom Admin veröffentlichten Plugins.
class PluginCatalogCubit extends Cubit<PluginCatalogState> {
  PluginCatalogCubit(this._loadCatalog) : super(const PluginCatalogState());

  final LoadPluginCatalog _loadCatalog;

  Future<void> load() async {
    emit(const PluginCatalogState());
    final result = await _loadCatalog();
    if (isClosed) return;
    result.when(
      (entries) => emit(
        PluginCatalogState(status: PluginCatalogStatus.ready, entries: entries),
      ),
      (failure) => emit(
        PluginCatalogState(
          status: PluginCatalogStatus.failure,
          message: failure.message,
        ),
      ),
    );
  }
}

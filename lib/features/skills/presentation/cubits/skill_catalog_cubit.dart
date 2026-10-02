import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/skill_catalog.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/usecases/skill_catalog_use_cases.dart';
import 'skill_catalog_state.dart';

/// Suche und Bestenliste des Katalogs. Eingaben werden entprellt und erst ab
/// zwei Zeichen gesendet; das schont das Rate-Limit von skills.sh (der Server
/// hält es zusätzlich selbst ein und meldet die Wartezeit).
class SkillCatalogCubit extends Cubit<SkillCatalogState> {
  SkillCatalogCubit(this._isAvailable, this._search, this._browse)
    : super(const SkillCatalogState());

  static const debounce = Duration(milliseconds: 400);
  static const minimumQueryLength = 2;

  final IsSkillCatalogAvailable _isAvailable;
  final SearchSkillCatalog _search;
  final BrowseSkillCatalog _browse;
  Timer? _timer;

  Future<void> load() async {
    emit(const SkillCatalogState());
    if (!await _isAvailable()) {
      if (!isClosed) {
        emit(const SkillCatalogState(status: SkillCatalogStatus.unavailable));
      }
      return;
    }
    await _showBestList();
  }

  void queryChanged(String text) {
    _timer?.cancel();
    final query = text.trim();
    if (query.length < minimumQueryLength) {
      _timer = Timer(debounce, _showBestList);
      return;
    }
    emit(SkillCatalogState(status: SkillCatalogStatus.loading, query: query));
    _timer = Timer(debounce, () => _runSearch(query));
  }

  Future<void> retry() =>
      state.query.isEmpty ? _showBestList() : _runSearch(state.query);

  Future<void> _showBestList() async {
    emit(const SkillCatalogState(status: SkillCatalogStatus.loading));
    final result = await _browse(CatalogView.trending, 0);
    if (isClosed) return;
    result.when(
      (page) => emit(
        SkillCatalogState(status: SkillCatalogStatus.ready, items: page.items),
      ),
      _emitFailure,
    );
  }

  Future<void> _runSearch(String query) async {
    final result = await _search(query);
    if (isClosed || state.query != query) return;
    result.when(
      (items) => emit(
        SkillCatalogState(
          status: SkillCatalogStatus.ready,
          query: query,
          items: items,
        ),
      ),
      _emitFailure,
    );
  }

  void _emitFailure(SkillFailure failure) {
    emit(
      SkillCatalogState(
        status: SkillCatalogStatus.failure,
        query: state.query,
        message: failure.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

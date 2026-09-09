import 'package:flutter_bloc/flutter_bloc.dart';

import 'logger.dart';

class ApplicationBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    logException(
      message: 'Unbehandelter BLoC-Fehler in ${bloc.runtimeType}.',
      error: error,
      stackTrace: stackTrace,
      name: 'bloc',
    );
    super.onError(bloc, error, stackTrace);
  }
}

import 'package:get_it/get_it.dart';
import 'package:syscat2/features/connections/domain/repositories/connection_repository.dart';
import 'package:syscat2/features/connections/domain/usecases/connection_use_cases.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

/// Use Cases und Cubit der Verbindungen — in beiden Betriebsvarianten gleich;
/// nur das Repository unterscheidet sich und wird vorher registriert.
void registerConnectionDependencies(GetIt locator) {
  locator
    ..registerLazySingleton(
      () => WatchConnections(locator<ConnectionRepository>()),
    )
    ..registerLazySingleton(
      () => CreateConnection(locator<ConnectionRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateConnection(locator<ConnectionRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteConnection(locator<ConnectionRepository>()),
    )
    ..registerLazySingleton(
      () => TestConnection(locator<ConnectionRepository>()),
    )
    ..registerFactory(
      () => ConnectionsCubit(
        locator<WatchConnections>(),
        locator<CreateConnection>(),
        locator<UpdateConnection>(),
        locator<DeleteConnection>(),
        locator<TestConnection>(),
        locator<GetCurrentTeamId>(),
      ),
    );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import '../../features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_ai_model_settings.dart';
import '../../features/settings/domain/usecases/save_ai_provider_settings.dart';
import '../../features/settings/infrastructure/repositories/firestore_settings_repository.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';
import '../../features/task_builder/domain/repositories/task_definition_repository.dart';
import '../../features/task_builder/domain/repositories/task_runner_repository.dart';
import '../../features/task_builder/domain/usecases/execute_task_definition.dart';
import '../../features/task_builder/domain/usecases/get_draft_task_definition.dart';
import '../../features/task_builder/domain/usecases/save_draft_task_definition.dart';
import '../../features/task_builder/infrastructure/datasources/local_genkit_proxy_task_client.dart';
import '../../features/task_builder/infrastructure/datasources/local_genkit_task_client.dart';
import '../../features/task_builder/infrastructure/repositories/in_memory_task_definition_repository.dart';
import '../../features/task_builder/infrastructure/repositories/local_genkit_task_runner_repository.dart';
import '../../features/task_builder/presentation/cubits/task_builder_cubit.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/domain/usecases/ensure_user_profile.dart';
import '../../features/user/domain/usecases/get_user_profile.dart';
import '../../features/user/infrastructure/repositories/firestore_user_repository.dart';
import '../routing/app_router.dart';

final serviceLocator = GetIt.instance;

void configureDependencies() {
  serviceLocator
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(serviceLocator<FirebaseAuth>()),
    )
    ..registerLazySingleton<UserRepository>(
      () => FirestoreUserRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => FirestoreSettingsRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton<TaskDefinitionRepository>(
      InMemoryTaskDefinitionRepository.new,
    )
    ..registerLazySingleton<LocalGenkitTaskClient>(
      LocalGenkitProxyTaskClient.new,
    )
    ..registerLazySingleton<TaskRunnerRepository>(
      () => LocalGenkitTaskRunnerRepository(
        serviceLocator<LocalGenkitTaskClient>(),
      ),
    )
    ..registerLazySingleton(() => SignOut(serviceLocator<AuthRepository>()))
    ..registerLazySingleton(
      () => SignUpWithEmailAndPassword(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => SignInWithEmailAndPassword(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => EnsureUserProfile(serviceLocator<UserRepository>()),
    )
    ..registerLazySingleton(
      () => GetUserProfile(serviceLocator<UserRepository>()),
    )
    ..registerLazySingleton(
      () => GetCurrentUserProfile(
        authRepository: serviceLocator<AuthRepository>(),
        userRepository: serviceLocator<UserRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => GetAiModelSettings(serviceLocator<SettingsRepository>()),
    )
    ..registerLazySingleton(
      () => SaveAiProviderSettings(serviceLocator<SettingsRepository>()),
    )
    ..registerLazySingleton(
      () => GetDraftTaskDefinition(serviceLocator<TaskDefinitionRepository>()),
    )
    ..registerLazySingleton(
      () => SaveDraftTaskDefinition(serviceLocator<TaskDefinitionRepository>()),
    )
    ..registerLazySingleton(
      () => ExecuteTaskDefinition(serviceLocator<TaskRunnerRepository>()),
    )
    ..registerFactory(
      () => AuthCubit(
        signUp: serviceLocator<SignUpWithEmailAndPassword>(),
        signIn: serviceLocator<SignInWithEmailAndPassword>(),
        signOut: serviceLocator<SignOut>(),
        ensureUserProfile: serviceLocator<EnsureUserProfile>(),
      ),
    )
    ..registerFactory(
      () => SettingsCubit(
        getCurrentUserProfile: serviceLocator<GetCurrentUserProfile>(),
        ensureUserProfile: serviceLocator<EnsureUserProfile>(),
        getAiModelSettings: serviceLocator<GetAiModelSettings>(),
        saveAiProviderSettings: serviceLocator<SaveAiProviderSettings>(),
      ),
    )
    ..registerFactory(
      () => TaskBuilderCubit(
        getDraftTaskDefinition: serviceLocator<GetDraftTaskDefinition>(),
        saveDraftTaskDefinition: serviceLocator<SaveDraftTaskDefinition>(),
      ),
    )
    ..registerLazySingleton(
      () => AppRouter(authRepository: serviceLocator<AuthRepository>()),
      dispose: (router) => router.dispose(),
    );
}

import 'package:bloc/bloc.dart';

import '../../../user/domain/entities/user_email.dart';
import '../../../user/domain/usecases/ensure_user_profile.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/usecases/sign_in_with_email_and_password.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email_and_password.dart';
import 'auth_form_state.dart';

/// Zustandsverwaltung für das Auth-Formular. Sitzt nur in der [AuthPage]
/// und wird beim Verlassen wieder entsorgt — Session-Themen (currentUser,
/// signOut) laufen bewusst über den globalen `AuthSessionCubit`.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit({
    required this.signUpUseCase,
    required this.signInUseCase,
    required this.ensureUserProfileUseCase,
    required this.signOutUseCase,
  }) : super(const AuthFormState());

  final SignUpWithEmailAndPassword signUpUseCase;
  final SignInWithEmailAndPassword signInUseCase;
  final EnsureUserProfile ensureUserProfileUseCase;
  final SignOut signOutUseCase;

  /// Modus umschalten. Setzt alle Eingaben zurück, damit ein alter Name aus
  /// einem verworfenen SignUp nicht heimlich in den nächsten Submit gerät.
  void changeMode(AuthMode mode) {
    _emitState(AuthFormState(mode: mode));
  }

  void updateName(String name) {
    _emitState(state.copyWith(name: name, clearMessage: true));
  }

  void updateEmail(String email) {
    _emitState(state.copyWith(email: email, clearMessage: true));
  }

  void updatePassword(String password) {
    _emitState(state.copyWith(password: password, clearMessage: true));
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
    final failure = _validateInputs();
    if (failure != null) return _emitFailure(failure.message);
    _emitState(
      state.copyWith(status: AuthFormStatus.submitting, clearMessage: true),
    );
    final authUserOrFailure = state.mode == AuthMode.signUp
        ? await signUpUseCase(_signUpParams())
        : await signInUseCase(_signInParams());
    if (isClosed) return;
    await authUserOrFailure.when(
      _ensureProfileAndEmitSuccess,
      (failure) async => _emitFailure(failure.message),
    );
  }

  AuthFailure? _validateInputs() {
    if (state.mode == AuthMode.signUp && state.name.trim().length < 2) {
      return const AuthFailure(AuthFailureKind.invalidName);
    }
    if (EmailAddress.tryCreate(state.email) == null) {
      return const AuthFailure(AuthFailureKind.invalidEmail);
    }
    if (state.password.length < 6) {
      return const AuthFailure(AuthFailureKind.weakPassword);
    }
    return null;
  }

  SignUpParams _signUpParams() {
    return SignUpParams(
      name: state.name,
      email: EmailAddress.tryCreate(state.email)!,
      password: state.password,
    );
  }

  SignInParams _signInParams() {
    return SignInParams(
      email: EmailAddress.tryCreate(state.email)!,
      password: state.password,
    );
  }

  void _emitFailure(String message) {
    _emitState(
      state.copyWith(status: AuthFormStatus.failure, message: message),
    );
  }

  void _emitState(AuthFormState nextState) {
    if (!isClosed) emit(nextState);
  }

  Future<void> _ensureProfileAndEmitSuccess(AuthUser authUser) async {
    final email = UserEmail.tryCreate(authUser.email);
    if (email == null) return _handleProfileFailure(profileEmailInvalid: true);
    final userProfileOrFailure = await ensureUserProfileUseCase(
      EnsureUserProfileParams(
        id: authUser.id,
        email: email,
        displayName: _profileDisplayName(authUser),
      ),
    );
    if (isClosed) return;
    userProfileOrFailure.when(
      (_) => _emitState(
        AuthFormState(
          mode: state.mode,
          status: AuthFormStatus.success,
        ),
      ),
      (_) => _handleProfileFailure(),
    );
  }

  /// FirebaseAuth war erfolgreich, aber der Firestore-Profil-Sync ist
  /// gescheitert. Der Router beobachtet `authStateChanges` und würde den
  /// User sonst in die App durchreichen, wo er ohne `users/{uid}`-Dokument
  /// nichts tun kann. Deshalb loggen wir ihn hier wieder aus und behalten
  /// eine sprechende Fehlermeldung im Formular. Die Passwort-Eingabe wird
  /// dabei geleert, damit der User sie neu eingibt.
  Future<void> _handleProfileFailure({bool profileEmailInvalid = false}) async {
    final failure = profileEmailInvalid
        ? const AuthFailure(AuthFailureKind.invalidEmail)
        : const AuthFailure(AuthFailureKind.profileSyncFailed);
    await signOutUseCase();
    if (isClosed) return;
    _emitState(
      state.copyWith(
        status: AuthFormStatus.failure,
        message: failure.message,
        password: '',
      ),
    );
  }

  String _profileDisplayName(AuthUser authUser) {
    if (state.mode == AuthMode.signUp) return state.name.trim();
    final authName = authUser.displayName.trim();
    return authName.isEmpty ? authUser.email : authName;
  }
}

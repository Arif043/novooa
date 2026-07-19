import 'package:bloc/bloc.dart';

import '../../../user/domain/entities/user_email.dart';
import '../../../user/domain/usecases/ensure_user_profile.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/usecases/sign_in_with_email_and_password.dart';
import '../../domain/usecases/sign_up_with_email_and_password.dart';
import 'auth_form_state.dart';

class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit({
    required this.signUpUseCase,
    required this.signInUseCase,
    required this.ensureUserProfileUseCase,
  }) : super(const AuthFormState());

  final SignUpWithEmailAndPassword signUpUseCase;
  final SignInWithEmailAndPassword signInUseCase;
  final EnsureUserProfile ensureUserProfileUseCase;
  String _name = '';
  String _email = '';
  String _password = '';

  void changeMode(AuthMode mode) => _emitState(AuthFormState(mode: mode));

  void updateName(String name) => _name = name;

  void updateEmail(String email) => _email = email;

  void updatePassword(String password) => _password = password;

  Future<void> submit() async {
    final failure = _validateInputs();
    if (failure != null) return _emitFailure(failure.message);
    _emitState(state.copyWith(status: AuthFormStatus.submitting));
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
    if (state.mode == AuthMode.signUp && _name.trim().length < 2) {
      return const AuthFailure(AuthFailureKind.invalidName);
    }
    if (EmailAddress.tryCreate(_email) == null) {
      return const AuthFailure(AuthFailureKind.invalidEmail);
    }
    if (_password.length < 6) {
      return const AuthFailure(AuthFailureKind.weakPassword);
    }
    return null;
  }

  SignUpParams _signUpParams() {
    return SignUpParams(
      name: _name,
      email: EmailAddress.tryCreate(_email)!,
      password: _password,
    );
  }

  SignInParams _signInParams() {
    return SignInParams(
      email: EmailAddress.tryCreate(_email)!,
      password: _password,
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
    if (email == null) return _emitInvalidEmail();
    final userProfileOrFailure = await ensureUserProfileUseCase(
      EnsureUserProfileParams(
        id: authUser.id,
        email: email,
        displayName: _profileDisplayName(authUser),
      ),
    );
    if (isClosed) return;
    userProfileOrFailure.when(
      (_) => _emitState(state.copyWith(status: AuthFormStatus.success)),
      (failure) => _emitFailure(failure.message),
    );
  }

  void _emitInvalidEmail() {
    _emitFailure(const AuthFailure(AuthFailureKind.invalidEmail).message);
  }

  String _profileDisplayName(AuthUser authUser) {
    if (state.mode == AuthMode.signUp) return _name.trim();
    final authName = authUser.displayName.trim();
    return authName.isEmpty ? authUser.email : authName;
  }
}
